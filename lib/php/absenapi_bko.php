<?php
header('Content-Type: application/json');
// Report all errors but don't display them to the client; we will return structured JSON
error_reporting(E_ALL);
ini_set('display_errors', '0');
date_default_timezone_set('Asia/Jakarta');
session_start();
include "config.php";

// ================== SETUP LOG FILE ==================
$logFile = __DIR__ . "/../logs/log_absen_masuk.txt";
if (!file_exists(dirname($logFile))) {
    mkdir(dirname($logFile), 0777, true);
}
function writeLog($message) {
    global $logFile;
    $time = date("Y-m-d H:i:s");
    file_put_contents($logFile, "[$time] $message\n", FILE_APPEND);
}
// ====================================================
 
// Wrap main flow in try/catch so we always return structured JSON instead of a 500 stack trace
try {

// ================== WAKTU DAN HARI ==================
$tgl_hari_ini = date("Y-m-d");
$tgl_besok = date("Y-m-d", strtotime("+1 day"));
$tgl_hari_kemarin = date("Y-m-d", strtotime("-1 day"));
$jam_sekarang = date('H:i:s');
$wktmasuk = date("H:i:s");
$harimasuk = date("Y-m-d H:i:s");
$hari_inggris = date("l");
$hari_array = [
    'Sunday' => 'Minggu',
    'Monday' => 'Senin',
    'Tuesday' => 'Selasa',
    'Wednesday' => 'Rabu',
    'Thursday' => 'Kamis',
    'Friday' => 'Jumat',
    'Saturday' => 'Sabtu'
];
$hari_ini = $hari_array[$hari_inggris];

// ====================================================
// CEK KONEKSI DB
if ($mysqli->connect_error) {
    writeLog("ERROR: Koneksi DB gagal - " . $mysqli->connect_error);
    echo json_encode(['status' => 'error', 'message' => 'Database gagal terkoneksi']);
    exit;
}
} catch (Throwable $e) {
    // Log unexpected errors and return structured JSON instead of a raw 500 stack trace
    writeLog("UNCAUGHT EXCEPTION: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Internal server error',
        'error' => $e->getMessage()
    ]);
    exit;
}
// ================== VALIDASI INPUT ==================
if (!isset($_POST['latitude']) || !isset($_POST['longitude']) || !isset($_POST['username'])) {
    writeLog("ERROR: Data tidak lengkap dari POST");
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap']);
    exit;
}

$id_pegawai = $_POST['id_pegawai'];
$username = $_POST['username'];
$cabang = $_POST['cabang'];
$divisi = $_POST['divisi'];
$latitude = $_POST['latitude'];
$longitude = $_POST['longitude'];
$jenis_aturan = $_POST['jenis_aturan'];
$id_tmpt = $_POST['id_tmpt'] ?? null;
$avatar = !empty($_POST['avatar']) ? $_POST['avatar'] : '';
$tmpt_dikunjungi = $_POST['tmpt_dikunjungi'] ?? null;

writeLog("START ABSEN | Pegawai:$id_pegawai | Username:$username | Cabang:$cabang | Aturan:$jenis_aturan | Lat:$latitude | Long:$longitude");

// ================== CEK ABSEN AKTIF ==================
$stmt_cek = $mysqli->prepare("SELECT absen_id FROM tb_absen_bko WHERE id_pegawai = ? AND wktkeluar IS NULL AND wktmasuk IS NOT NULL");
$stmt_cek->bind_param("i", $id_pegawai);
$stmt_cek->execute();
$result_cek = $stmt_cek->get_result();
if (!empty($_SESSION['id_absen']) || isset($_SESSION['id_absen'])) {
    writeLog("ERROR: Pegawai $id_pegawai sudah absen hari ini");
    echo json_encode(['status' => 'error', 'message' => 'Absen sudah dilakukan hari ini']);
    exit;
}
$stmt_cek->close();

// ================== VALIDASI FOTO ==================
if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
    writeLog("ERROR: Upload foto gagal untuk pegawai $id_pegawai");
    echo json_encode(['status' => 'error', 'message' => 'File tidak dikirim atau terjadi kesalahan saat upload']);
    exit;
}

// ================== AMBIL DATA SHIFT ==================
$sql = "
    SELECT s.* 
    FROM tb_shift s
    JOIN tb_pegawai p ON s.id_jadwal = p.id_jadwal
    WHERE p.id_pegawai = ?
";
$stmt = $mysqli->prepare($sql);
$stmt->bind_param("i", $id_pegawai);
$stmt->execute();
$result = $stmt->get_result();

$jam_masuk = [];
$jml_jam = '0';
$tipe_shift = '';
$is_tomorrow = 0;

while ($row = $result->fetch_assoc()) {
    if ($row['tipe'] === 'flexibel') {
        $jam_masuk = array_filter([$row['jam_masuk1'], $row['jam_masuk2'], $row['jam_masuk3'], $row['jam_masuk4']]);
        $jml_jam = $row['jml_jam'];
        $tipe_shift = $row['tipe'];
        break;
    } elseif ($row['tipe'] === 'statis' && $row['hari'] === $hari_ini) {
        $jam_masuk = array_filter([$row['jam_masuk1'], $row['jam_masuk2'], $row['jam_masuk3'], $row['jam_masuk4']]);
        $is_tomorrow = $row['is_tomorrow'];
        $tipe_shift = $row['tipe'];
        $jml_jam = $row['jml_jam'];
        break;
    }
}
$stmt->close();
writeLog("Shift ditemukan tipe=$tipe_shift jml_jam=$jml_jam");

// ================== HITUNG JAM TERDEKAT ==================
$jam_masuk_all = array_merge(
    array_map(fn($jam) => "$tgl_hari_kemarin $jam", $jam_masuk),
    array_map(fn($jam) => "$tgl_hari_ini $jam", $jam_masuk),
    array_map(fn($jam) => "$tgl_besok $jam", $jam_masuk)
);
sort($jam_masuk_all);
$jam_masuk_terdekat = null;
$selisih_terkecil = null;
foreach ($jam_masuk_all as $jam) {
    $selisih = abs(strtotime($jam) - strtotime($harimasuk));
    if ($selisih_terkecil === null || $selisih < $selisih_terkecil) {
        $selisih_terkecil = $selisih;
        $jam_masuk_terdekat = $jam;
    }
}
$telatMenit = 0;
if (strtotime($harimasuk) > strtotime($jam_masuk_terdekat)) {
    $selisihDetik = strtotime($harimasuk) - strtotime($jam_masuk_terdekat);
    $telatMenit = ceil($selisihDetik / 60);
}
writeLog("Jam Masuk Terdekat: $jam_masuk_terdekat | Telat: {$telatMenit} menit");

// ================== PROSES ABSEN FLEXIBEL ==================
if ($jenis_aturan == '1') {
    $filename = "absen_{$id_pegawai}_" . time() . ".jpg";
    $stmt = $mysqli->prepare("INSERT INTO tb_absen_bko 
        (id_pegawai, harimasuk, wktmasuk, jam_masuk, jml_jam, latitude, longitude, foto, username, id_cabang, dtg_terlambat) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("isssissssii", $id_pegawai, $harimasuk, $wktmasuk, $jam_masuk_terdekat, $jml_jam, $latitude, $longitude, $filename, $username, $cabang, $telatMenit);
    writeLog("INSERT tb_absen_bko FLEXIBEL | Pegawai:$id_pegawai | File:$filename");
    
    if ($stmt->execute()) {
        $targetDir = "../uploads/absensi/";
        if (!file_exists($targetDir)) mkdir($targetDir, 0755, true);
        $targetFile = $targetDir . $filename;
        if (!move_uploaded_file($_FILES['foto']['tmp_name'], $targetFile)) {
            writeLog("ERROR: Gagal menyimpan foto ke server $targetFile");
            echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan foto ke server']);
            exit;
        }
        unset($_SESSION['id_absen'], $_SESSION['action_absen']);
        writeLog("SUCCESS: Absen FLEXIBEL disimpan untuk pegawai $id_pegawai");
        echo json_encode(['status' => 'success', 'message' => 'Absensi berhasil disimpan']);
    } else {
        writeLog("ERROR: Query gagal FLEXIBEL - " . $stmt->error);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data ke database']);
    }
    $stmt->close();

} elseif (in_array($jenis_aturan, ['2', '3', '4'])) {
    if (empty($id_tmpt)) {
        writeLog("ERROR: Lokasi absen kosong untuk $id_pegawai");
        echo json_encode(['status' => 'error', 'message' => 'Absen Gagal!! Pilih Lokasi Absen']);
        exit;
    }

    $targetDir = "../uploads/absensi/";
    if (!file_exists($targetDir)) mkdir($targetDir, 0755, true);
    $filename = "absen_{$id_pegawai}_" . time() . ".jpg";
    $targetFile = $targetDir . $filename;
    if (!move_uploaded_file($_FILES['foto']['tmp_name'], $targetFile)) {
        writeLog("ERROR: Upload gagal $filename");
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan foto ke server']);
        exit;
    }

    $stmt = $mysqli->prepare("INSERT INTO tb_absen_bko 
        (id_pegawai, harimasuk, wktmasuk, jam_masuk, jml_jam, latitude, longitude, foto, username, id_cabang, id_tmpt) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("isssissssii", $id_pegawai, $harimasuk, $wktmasuk, $jam_masuk_terdekat, $jml_jam, $latitude, $longitude, $filename, $username, $cabang, $id_tmpt);
    writeLog("INSERT tb_absen_bko LOKASI | Pegawai:$id_pegawai | Lokasi:$id_tmpt | File:$filename");

    if ($stmt->execute()) {
        if ($jenis_aturan == '3') {
            $tmpt_dikunjungi_json = $tmpt_dikunjungi;
            $tmpt_dikunjungi_array = json_decode($tmpt_dikunjungi_json, true);
            if (!is_array($tmpt_dikunjungi_array)) $tmpt_dikunjungi_array = [];
            $tmpt_dikunjungi_array[] = $id_tmpt;
            $tmpt_dikunjungix = json_encode($tmpt_dikunjungi_array);

            $stmt2 = $mysqli->prepare("UPDATE tb_aturan_lokasi_pegawai SET tmpt_dikunjungi = ? WHERE id_pegawai = ?");
            $stmt2->bind_param("si", $tmpt_dikunjungix, $id_pegawai);
            $stmt2->execute();
            $stmt2->close();
            writeLog("UPDATE tb_aturan_lokasi_pegawai | Pegawai:$id_pegawai | Data:$tmpt_dikunjungix");
        }

        unset($_SESSION['id_absen'], $_SESSION['action_absen']);
        writeLog("SUCCESS: Absen LOKASI disimpan untuk $id_pegawai");
        echo json_encode(['status' => 'success', 'message' => 'Absensi berhasil disimpan']);
    } else {
        writeLog("ERROR: Query gagal LOKASI - " . $stmt->error);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan data ke database']);
    }
    $stmt->close();
}

?>
