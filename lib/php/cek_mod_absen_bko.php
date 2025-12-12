<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

include "../include/config.php";

// ============================
// ?? Fungsi bantu untuk respon JSON
// ============================
function response($data) {
    echo json_encode($data, JSON_PRETTY_PRINT);
    exit;
}

// ============================
// ?? Cek koneksi database
// ============================
if (!isset($mysqli) || $mysqli->connect_errno) {
    response([
        "status" => false,
        "message" => "Koneksi database gagal: " . ($mysqli->connect_error ?? 'unknown error')
    ]);
}

// ============================
// ?? Endpoint test koneksi
// ============================
if (isset($_GET['test'])) {
    response([
        "status" => true,
        "message" => "API cek_mod_absen aktif dan terhubung ke database."
    ]);
}

// ============================
// ?? Pastikan method GET
// ============================
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    response([
        "status" => false,
        "message" => "Method not allowed. Use GET."
    ]);
}

// ============================
// ?? Ambil parameter idpegawai
// ============================
if (!isset($_GET['idpegawai'])) {
    response([
        "status" => false,
        "message" => "Parameter idpegawai diperlukan."
    ]);
}

$idpegawai = intval($_GET['idpegawai']);

// ============================
// ?? Validasi pegawai
// ============================
$cekPegawai = $mysqli->prepare("SELECT id_pegawai, nama_pegawai FROM tb_pegawai WHERE id_pegawai = ?");
$cekPegawai->bind_param("i", $idpegawai);
$cekPegawai->execute();
$resPegawai = $cekPegawai->get_result();

if ($resPegawai->num_rows === 0) {
    response([
        "status" => false,
        "message" => "Pegawai dengan ID $idpegawai tidak ditemukan."
    ]);
}

$dataPegawai = $resPegawai->fetch_assoc();
$cekPegawai->close();

// ============================
// ?? Cek apakah sudah absen hari ini
// ============================
$today = date('Y-m-d');
$has_absen_today = false;
$today_absen_id = null;
$today_harimasuk = null;
$stmtToday = $mysqli->prepare("SELECT absen_id, harimasuk FROM tb_absen_bko WHERE id_pegawai = ? AND DATE(harimasuk) = ? ORDER BY absen_id DESC LIMIT 1");
if ($stmtToday) {
    $stmtToday->bind_param("is", $idpegawai, $today);
    $stmtToday->execute();
    $resToday = $stmtToday->get_result();
    if ($rT = $resToday->fetch_assoc()) {
        $has_absen_today = true;
        $today_absen_id = $rT['absen_id'];
        $today_harimasuk = $rT['harimasuk'];
    }
    $stmtToday->close();
}

// ============================
// ?? Validasi aturan lokasi pegawai
// ============================
$cekAturan = $mysqli->prepare("SELECT * FROM tb_aturan_lokasi_pegawai WHERE id_pegawai = ?");
$cekAturan->bind_param("i", $idpegawai);
$cekAturan->execute();
$resAturan = $cekAturan->get_result();

if ($resAturan->num_rows > 0) {
    $dataAturan = $resAturan->fetch_assoc();
    $jenis_aturan = $dataAturan['jenis_aturan'];
} else {
    $jenis_aturan = null; // jika tidak ada aturan
}
$cekAturan->close();

// ============================
// ?? Cek data absen aktif
// ============================
$sql = "
    SELECT 
        absen_id, 
        wktmasuk,
        harimasuk,
        jam_masuk,
        jml_jam
    FROM tb_absen_bko
    WHERE id_pegawai = ? 
      AND wktmasuk IS NOT NULL 
      AND wktkeluar IS NULL
    ORDER BY absen_id DESC 
    LIMIT 1
";

$stmt = $mysqli->prepare($sql);
$stmt->bind_param("i", $idpegawai);
$stmt->execute();
$result = $stmt->get_result();

// ============================
// ?? Jika ada data absen aktif
// ============================
if ($row = $result->fetch_assoc()) {
    $batas = ((int)$row['jml_jam']) + 300;
    $jam_masuk = $row['jam_masuk'];
    $selisih = selisihMenit($jam_masuk); // Fungsi ada di config.php

    if ($selisih <= $batas) {
        $response = [
            "status" => true,
            "action_absen" => "absenpulang",
            "id_absen" => $row['absen_id'],
            "id_pegawai" => $idpegawai,
            "nama_pegawai" => $dataPegawai['nama_pegawai'],
            "jenis_aturan" => $jenis_aturan,
            "has_absen_today" => $has_absen_today,
            "today_absen_id" => $today_absen_id,
            "today_harimasuk" => $today_harimasuk,
            "absen_masuk" => $row['harimasuk'],
            "jam_masuk" => $jam_masuk,
            "selisih_menit" => $selisih,
            "batas_menit" => $batas,
            "next_mod" => "scan_pulang",
            "message" => "Sudah waktunya absen pulang."
        ];
    } else {
        $response = [
            "status" => true,
            "action_absen" => "absenmasuk",
            "id_absen" => null,
            "id_pegawai" => $idpegawai,
            "nama_pegawai" => $dataPegawai['nama_pegawai'],
            "jenis_aturan" => $jenis_aturan,
            "has_absen_today" => $has_absen_today,
            "today_absen_id" => $today_absen_id,
            "today_harimasuk" => $today_harimasuk,
            "absen_masuk" => "__:__:__",
            "jam_masuk" => $jam_masuk,
            "selisih_menit" => $selisih,
            "batas_menit" => $batas,
            "next_mod" => "scan_masuk",
            "message" => "Belum waktunya absen pulang."
        ];
    }
} else {
    // ?? Tidak ada data absen aktif
    $response = [
        "status" => true,
        "action_absen" => "absenmasuk",
        "id_absen" => null,
        "id_pegawai" => $idpegawai,
        "nama_pegawai" => $dataPegawai['nama_pegawai'],
        "jenis_aturan" => $jenis_aturan,
        "has_absen_today" => $has_absen_today,
        "today_absen_id" => $today_absen_id,
        "today_harimasuk" => $today_harimasuk,
        "absen_masuk" => "__:__:__",
        "jam_masuk" => null,
        "selisih_menit" => null,
        "batas_menit" => null,
        "next_mod" => "scan_masuk",
        "message" => "Tidak ada data absen aktif."
    ];
}

$stmt->close();
$mysqli->close();

// ? Output akhir
response($response);
?>
