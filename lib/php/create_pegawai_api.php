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

// Collect POST fields
$fields = [
    'id_pegawai','nama_pegawai','jk','nip','nik','no_kk','tmpt_lahir','tgl_lahir','pendidikan','alamat',
    'id_golongan','agama','id_jabatan','tmpt_tugas','status','id_divisi','id_cabang','username','psw','avatar',
    'temp','kode_jam','nama_jabatan','id_grup','face_descriptor','create_date','telp','telp_darurat','email',
    'auth','tmt','nosprint','tgl_joint','tgl_akhir_pkwt','no_rekening','npwp','bpjs_tk','bpjs_kes','jml_tanggungan',
    'status_kawin','nama_ibu','id_jadwal'
];

$data = [];
foreach ($fields as $f) {
    if (isset($_POST[$f])) {
        $data[$f] = $_POST[$f];
    } else {
        $data[$f] = null;
    }
}

// Handle avatar upload (optional)
$avatar_file = null;
$uploadDir = __DIR__ . "/../assets/img/pegawai/";
if (!is_dir($uploadDir)) {
    @mkdir($uploadDir, 0755, true);
}
if (isset($_FILES['avatar']) && $_FILES['avatar']['error'] == 0) {
    $origName = basename($_FILES['avatar']['name']);
    $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
    $allowed = ['jpg','jpeg','png','gif','webp'];
    if (!in_array($ext, $allowed)) {
        $ext = 'jpg';
    }
    $fileName = 'avatar_' . ($data['id_pegawai'] ?? 'new') . '_' . time() . '.' . $ext;
    $uploadPath = $uploadDir . $fileName;
    if (move_uploaded_file($_FILES['avatar']['tmp_name'], $uploadPath)) {
        $avatar_file = $fileName;
        $data['avatar'] = $fileName;
    }
}

// Default create_date if not provided
if (empty($data['create_date'])) {
    $data['create_date'] = date('Y-m-d H:i:s');
}

// Build insert
$columns = [];
$placeholders = [];
$values = [];
foreach ($data as $k => $v) {
    // skip nulls to allow DB defaults
    if ($v !== null) {
        $columns[] = "`$k`";
        $placeholders[] = '?';
        $values[] = $v;
    }
}

if (count($columns) === 0) {
    echo json_encode(["success" => false, "message" => "Tidak ada data yang disediakan"]);
    exit;
}

$sql = "INSERT INTO `tb_pegawai` (" . implode(',', $columns) . ") VALUES (" . implode(',', $placeholders) . ")";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    $conn->close();
    exit;
}

// Bind all as strings
$types = str_repeat('s', count($values));
$bind_names[] = $types;
for ($i=0;$i<count($values);$i++) {
    $bind_name = 'bind' . $i;
    $$bind_name = $values[$i];
    $bind_names[] = &$$bind_name;
}
call_user_func_array([$stmt, 'bind_param'], $bind_names);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Pegawai berhasil dibuat",
        "insert_id" => $stmt->insert_id
    ]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>
