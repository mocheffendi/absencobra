<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

include "../include/config.php";
$conn = new mysqli($database_host1, $database_username1, $database_password1, $database_name1);

if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Koneksi gagal"]);
    exit;
}

// =============== VALIDASI TOKEN HEADER =================
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? ($_SERVER['HTTP_AUTHORIZATION'] ?? '');

if (!preg_match('/Bearer\s(\S+)/', $authHeader, $match)) {
    echo json_encode(["success" => false, "message" => "Token tidak ditemukan"]);
    exit;
}

$token = $match[1];

// cek token di database pegawai
$sql = "SELECT id_pegawai, nama_pegawai, id_cabang 
        FROM tb_pegawai 
        WHERE auth = ? LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $token);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Token tidak valid"]);
    exit;
}

$pegawai = $res->fetch_assoc();
$id_pegawai = $pegawai['id_pegawai'];
// Normalize id_cabang: if empty or non-numeric, default to 0 to avoid inserting SQL NULL
$id_cabang_raw = isset($pegawai['id_cabang']) ? $pegawai['id_cabang'] : '';
$id_cabang = (is_numeric($id_cabang_raw) && $id_cabang_raw !== '') ? (int)$id_cabang_raw : 0;
$stmt->close();

// ================== DATA INPUT ==================
$uraian = $_POST['uraian'] ?? '';

if (!$uraian) {
    echo json_encode(["success" => false, "message" => "Uraian wajib diisi"]);
    exit;
}

// ================== FILE BEFORE ==================
$before_file = null;
$uploadDir = __DIR__ . "/../assets/img/filekinerja/";
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0755, true);
}
if (isset($_FILES['before']) && $_FILES['before']['error'] == 0) {
    $origName = basename($_FILES['before']['name']);
    $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
    $allowed = ['jpg','jpeg','png','gif','webp'];
    if (!in_array($ext, $allowed)) {
        // fallback to jpg if extension not recognized
        $ext = 'jpg';
    }
    $fileName = 'kinerja_before_' . $id_pegawai . '_' . time() . '.' . $ext;
    $uploadPathRel = "../assets/img/filekinerja/" . $fileName; // relative path as requested
    $uploadPath = $uploadDir . $fileName; // absolute filesystem path
    if (move_uploaded_file($_FILES['before']['tmp_name'], $uploadPath)) {
        $before_file = $fileName;
    }
}

// ================== FILE AFTER ==================
$after_file = null;
if (isset($_FILES['after']) && $_FILES['after']['error'] == 0) {
    $origName = basename($_FILES['after']['name']);
    $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
    $allowed = ['jpg','jpeg','png','gif','webp'];
    if (!in_array($ext, $allowed)) {
        $ext = 'jpg';
    }
    $fileName = 'kinerja_after_' . $id_pegawai . '_' . time() . '.' . $ext;
    $uploadPathRel = "../assets/img/filekinerja/" . $fileName;
    $uploadPath = $uploadDir . $fileName;
    if (move_uploaded_file($_FILES['after']['tmp_name'], $uploadPath)) {
        $after_file = $fileName;
    }
}

// ================== TANGGAL & JAM SERVER ==================
$tgl  = date("Y-m-d");
$jam  = date("H:i:s");

// selesai masih NULL — dikontrol server lain
$tgl_selesai = null;
$jam_selesai = null;

// ================== INSERT KE TABEL ==================
$sql = "INSERT INTO `tb_kinerja` 
    (`id_pegawai`, `id_cabang`, `tgl`, `jam`, `before`, `tgl_selesai`, `jam_selesai`, `after`, `uraian`)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    $conn->close();
    exit;
}
$stmt->bind_param(
    "iisssssss",
    $id_pegawai,
    $id_cabang,
    $tgl,
    $jam,
    $before_file,
    $tgl_selesai,
    $jam_selesai,
    $after_file,
    $uraian
);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Kinerja berhasil disimpan",
        "id_kinerja" => $stmt->insert_id,
        "id_pegawai" => (int) $id_pegawai,
        "id_cabang" => (int) $id_cabang,
        "tgl" => $tgl,
        "jam" => $jam,
        "before" => $before_file,
        "tgl_selesai" => $tgl_selesai,
        "jam_selesai" => $jam_selesai,
        "after" => $after_file,
        "uraian" => $uraian
    ]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}
$stmt->close();
$conn->close();
?>
