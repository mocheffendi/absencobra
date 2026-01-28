<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "../include/config.php";

$conn = new mysqli($database_host1, $database_username1, $database_password1, $database_name1);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Koneksi gagal"]);
    exit;
}

$id_pegawai = isset($_GET['id_pegawai']) ? $conn->real_escape_string($_GET['id_pegawai']) : null;
$where = $id_pegawai ? "WHERE id_pegawai = '" . $id_pegawai . "'" : "";

$sql = "SELECT id_cuti, id_pegawai, tgl, tgl_sampai, jenis_cuti, lampiran, ket, id_cabang, st FROM tb_cuti $where ORDER BY tgl DESC";
$result = $conn->query($sql);

$data = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row['lampiran_url'] = $row['lampiran'] ?
            (isset($row['lampiran']) ?
                (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https://" : "http://") . $_SERVER['HTTP_HOST'] . "/assets/img/filecuti/" . $row['lampiran']
                : null)
            : null;
        $data[] = $row;
    }
}

echo json_encode([
    "success" => true,
    "count" => count($data),
    "data" => $data
]);
$conn->close();
