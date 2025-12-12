<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', '0');
date_default_timezone_set('Asia/Jakarta');

// Include DB config (must set $mysqli)
include __DIR__ . "/../include/config.php";

// Setup log
$logFile = __DIR__ . "/../logs/log_absen_keluar.txt";
if (!file_exists(dirname($logFile))) {
    mkdir(dirname($logFile), 0777, true);
}
function writeLog($msg) {
    global $logFile;
    $time = date("Y-m-d H:i:s");
    file_put_contents($logFile, "[$time] $msg\n", FILE_APPEND);
}

try {
    writeLog("=== START PROSES ABSEN KELUAR ===");
    writeLog("REQUEST POST: " . json_encode($_POST));
    if (!empty($_FILES)) writeLog("REQUEST FILES: " . json_encode($_FILES));

    if (!isset($mysqli) || $mysqli->connect_error) {
        writeLog("ERROR: Database gagal terkoneksi - " . ($mysqli->connect_error ?? 'no mysqli'));
        echo json_encode(['status' => 'error', 'message' => 'Database gagal terkoneksi']);
        exit;
    }

    if (!isset($_POST['id_pegawai']) || !isset($_POST['username']) || !isset($_POST['latitude']) || !isset($_POST['longitude'])) {
        writeLog("ERROR: Data input tidak lengkap" );
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
        exit;
    }

    $id_pegawai = (int) $_POST['id_pegawai'];
    $username = $_POST['username'];
    $latitude = $_POST['latitude'];
    $longitude = $_POST['longitude'];
    $id_absen_post = isset($_POST['id_absen']) && is_numeric($_POST['id_absen']) ? (int) $_POST['id_absen'] : null;

    writeLog("DATA PEGAWAI: id=$id_pegawai, username=$username");

    if (session_status() === PHP_SESSION_NONE) session_start();
    $id_absen = $id_absen_post;
    if (empty($id_absen) && isset($_SESSION['id_absen'])) $id_absen = (int) $_SESSION['id_absen'];

    if (empty($id_absen)) {
        $stmtF = $mysqli->prepare("SELECT absen_id FROM tb_absen_bko WHERE id_pegawai = ? AND jam_masuk IS NOT NULL AND harikeluar IS NULL ORDER BY harimasuk DESC LIMIT 1");
        if ($stmtF) {
            $stmtF->bind_param('i', $id_pegawai);
            $stmtF->execute();
            $resF = $stmtF->get_result();
            if ($r = $resF->fetch_assoc()) {
                $id_absen = (int) $r['absen_id'];
                writeLog("Fallback id_absen found: $id_absen");
            }
            $stmtF->close();
        }
    }

    if (empty($id_absen)) {
        writeLog("ERROR: Tidak ditemukan absen aktif untuk pegawai $id_pegawai");
        echo json_encode(['status' => 'error', 'message' => 'Belum Absen untuk Hari ini']);
        exit;
    }

    $stmt = $mysqli->prepare("SELECT jam_masuk, jml_jam, harimasuk FROM tb_absen_bko WHERE id_pegawai = ? AND absen_id = ? AND jam_masuk IS NOT NULL AND harikeluar IS NULL LIMIT 1");
    if (!$stmt) {
        writeLog('Prepare failed: ' . $mysqli->error);
        echo json_encode(['status'=>'error','message'=>'Internal server error']);
        exit;
    }
    $stmt->bind_param('ii', $id_pegawai, $id_absen);
    $stmt->execute();
    $res = $stmt->get_result();
    if (!($row = $res->fetch_assoc())) {
        writeLog("ERROR: Tidak ditemukan data absen masuk aktif untuk pegawai $id_pegawai with absen_id=$id_absen");
        echo json_encode(['status' => 'error', 'message' => 'Belum Absen untuk Hari ini']);
        exit;
    }
    $harimasuk = $row['harimasuk'];
    $jam_masuk = $row['jam_masuk'];
    $jml_jam = (int) $row['jml_jam'];
    $stmt->close();

    if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
        writeLog('ERROR: File foto tidak dikirim atau error upload');
        echo json_encode(['status'=>'error','message'=>'File tidak dikirim atau terjadi kesalahan saat upload']);
        exit;
    }

    $uploadDir = __DIR__ . "/../uploads/absensi/";
    if (!file_exists($uploadDir)) mkdir($uploadDir, 0755, true);
    $filename = sprintf('keluar_%d_%d.jpg', $id_pegawai, time());
    $target = $uploadDir . $filename;
    if (!move_uploaded_file($_FILES['foto']['tmp_name'], $target)) {
        writeLog('ERROR: Gagal menyimpan foto ke server ' . $target);
        echo json_encode(['status'=>'error','message'=>'Gagal menyimpan foto ke server']);
        exit;
    }
    writeLog('FOTO disimpan: ' . $target);

    $harikeluar = date('Y-m-d H:i:s');
    $wktkeluar = date('H:i:s');
    $selisih = strtotime($harikeluar) - strtotime($harimasuk);
    $durasi = (int) ceil($selisih / 60);
    $pulang_awal = 0;
    $dt = new DateTime($jam_masuk);
    $dt->modify("+{$jml_jam} minutes");
    $jamkeluar_target = $dt->format('Y-m-d H:i:s');
    if (strtotime($jamkeluar_target) > strtotime($harikeluar)) {
        $pulang_awal = (int) ceil((strtotime($jamkeluar_target) - strtotime($harikeluar)) / 60);
    }

    $sql = "UPDATE tb_absen_bko SET status = '0', pulang_awal = ?, jam_keluar = ?, harikeluar = ?, wktkeluar = ?, durasi = ?, fotok = ?, latitudek = ?, longitudek = ? WHERE id_pegawai = ? AND absen_id = ?";
    $up = $mysqli->prepare($sql);
    if (!$up) {
        writeLog('Prepare update failed: ' . $mysqli->error);
        echo json_encode(['status'=>'error','message'=>'Internal server error']);
        exit;
    }
    $up->bind_param('ssssssssii', $pulang_awal, $jamkeluar_target, $harikeluar, $wktkeluar, $durasi, $filename, $latitude, $longitude, $id_pegawai, $id_absen);
    if ($up->execute()) {
        writeLog('SUCCESS: absen keluar tersimpan untuk id_absen=' . $id_absen);
        echo json_encode(['status'=>'success','message'=>'Absensi berhasil disimpan']);
    } else {
        writeLog('ERROR MYSQL update: ' . $up->error);
        echo json_encode(['status'=>'error','message'=>'Gagal menyimpan data ke database']);
    }
    $up->close();

    writeLog('=== END PROSES ABSEN KELUAR ===');

} catch (Throwable $e) {
    writeLog('UNCAUGHT: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'Internal server error']);
    exit;
}

?>
        exit;
    }
    $stmtUp->bind_param('ssssssssii', $pulang_awal, $jamkeluar, $harikeluar, $wktkeluar, $durasi, $filename, $latitude, $longitude, $id_pegawai, $id_absen);
    if ($stmtUp->execute()) {
        writeLog("SUCCESS: Data absensi keluar tersimpan dengan benar untuk pegawai $id_pegawai");
        echo json_encode(['status' => 'success', 'message' => 'Absensi berhasil disimpan']);
    } else {
        writeLog("ERROR MYSQL: " . $stmtUp->error);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data ke database']);
    }
    $stmtUp->close();

    writeLog("=== END PROSES ===\n");
} catch (Throwable $e) {
    writeLog("UNCAUGHT EXCEPTION: " . $e->getMessage() . " in " . $e->getFile() . ':' . $e->getLine());
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Internal server error']);
    exit;
}

?>
// ================== UPDATE ABSENSI ==================

$sqlUpdate = "UPDATE tb_absen_bko SET 

    pulang_awal = ?, 

    jam_keluar = ?, 

    harikeluar = ?, 

    wktkeluar = ?, 

    durasi = ?, 

    fotok = ?, 

    latitudek = ?, 

    longitudek = ? 

    WHERE id_pegawai = ? AND absen_id = ?";

$stmt = $mysqli->prepare($sqlUpdate);

$stmt->bind_param("ssssssssii", $pulang_awal, $jamkeluar, $harikeluar, $wktkeluar, $durasi, $filename, $latitude, $longitude, $id_pegawai, $id_absen);



// ================== BUAT SQL UNTUK DICOBA DI PHPMYADMIN ==================

$sqlFinal = sprintf(

    "UPDATE tb_absen_bko SET pulang_awal='%s', jam_keluar='%s', harikeluar='%s', wktkeluar='%s', durasi='%s', fotok='%s', latitudek='%s', longitudek='%s' WHERE id_pegawai='%s' AND absen_id='%s';",

    $pulang_awal, $jamkeluar, $harikeluar, $wktkeluar, $durasi, $filename, $latitude, $longitude, $id_pegawai, $id_absen

);

writeLog("QUERY UPDATE: " . $sqlFinal);



// ================== EKSEKUSI QUERY ==================

if ($stmt->execute()) {

    writeLog("SUCCESS: Data absensi keluar tersimpan dengan benar untuk pegawai $id_pegawai");

    echo json_encode(['status' => 'success', 'message' => 'Absensi berhasil disimpan']);

} else {

    writeLog("ERROR MYSQL: " . $stmt->error);

    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data ke database']);

}

$stmt->close();



writeLog("=== END PROSES ===\n");

?>

