// ignore_for_file: non_constant_identifier_names

class User {
  final int id_pegawai;
  final String? nama;
  final String nip;
  final String? email;
  final String? alamat;
  final String username;
  final int id_jabatan;
  final int id_tmpt;
  final String? tmpt_tugas;
  final String? tgl_lahir;
  final String? divisi;
  final int id_cabang;
  final String avatar;
  final String? kode_jam;
  final String? status;
  final String? tgl_joint;
  final int? id_jadwal;
  final String jenis_aturan;
  final String? tmpt_dikunjungi;
  final String? token;

  User({
    required this.id_pegawai,
    this.nama,
    required this.nip,
    this.email,
    this.alamat,
    required this.username,
    required this.id_jabatan,
    required this.id_tmpt,
    this.tmpt_tugas,
    this.tgl_lahir,
    this.divisi,
    required this.id_cabang,
    required this.avatar,
    this.kode_jam,
    this.status,
    this.tgl_joint,
    this.id_jadwal,
    required this.jenis_aturan,
    this.tmpt_dikunjungi,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id_pegawai: map['id_pegawai'] is int
          ? map['id_pegawai']
          : int.tryParse(map['id_pegawai'].toString()) ?? 0,
      nama: map['nama'] as String?,
      nip: map['nip']?.toString() ?? '',
      email: map['email'] as String?,
      alamat: map['alamat'] as String?,
      username: map['username']?.toString() ?? '',
      id_jabatan: map['id_jabatan'] is int
          ? map['id_jabatan']
          : int.tryParse(map['id_jabatan'].toString()) ?? 0,
      id_tmpt: map['id_tmpt'] is int
          ? map['id_tmpt']
          : int.tryParse(map['id_tmpt'].toString()) ?? 0,
      tmpt_tugas: map['tmpt_tugas'] as String?,
      tgl_lahir: map['tgl_lahir'] as String?,
      divisi: map['divisi'] as String?,
      id_cabang: map['id_cabang'] is int
          ? map['id_cabang']
          : int.tryParse(map['id_cabang'].toString()) ?? 0,
      avatar: map['avatar']?.toString() ?? '',
      kode_jam: map['kode_jam'] as String?,
      status: map['status'] as String?,
      tgl_joint: map['tgl_joint'] as String?,
      id_jadwal: map['id_jadwal'] is int
          ? map['id_jadwal']
          : map['id_jadwal'] != null
          ? int.tryParse(map['id_jadwal'].toString())
          : null,
      jenis_aturan: map['jenis_aturan']?.toString() ?? '',
      tmpt_dikunjungi: map['tmpt_dikunjungi'] as String?,
      token: map['token'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_pegawai': id_pegawai,
      'nama': nama,
      'nip': nip,
      'email': email,
      'alamat': alamat,
      'username': username,
      'id_jabatan': id_jabatan,
      'id_tmpt': id_tmpt,
      'tmpt_tugas': tmpt_tugas,
      'tgl_lahir': tgl_lahir,
      'divisi': divisi,
      'id_cabang': id_cabang,
      'avatar': avatar,
      'kode_jam': kode_jam,
      'status': status,
      'tgl_joint': tgl_joint,
      'id_jadwal': id_jadwal,
      'jenis_aturan': jenis_aturan,
      'tmpt_dikunjungi': tmpt_dikunjungi,
      'token': token,
    };
  }
}
