// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id_pegawai,
    String? nama,
    required String nip,
    String? email,
    String? alamat,
    required String username,
    required int id_jabatan,
    required int id_tmpt,
    String? tmpt_tugas,
    String? tgl_lahir,
    String? divisi,
    required int id_cabang,
    required String avatar,
    String? avatar_lokal,
    String? kode_jam,
    String? status,
    String? tgl_joint,
    int? id_jadwal,
    required String jenis_aturan,
    String? tmpt_dikunjungi,
    String? token,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) {
    // Custom fromJson to handle null values and type casting errors
    try {
      return _$UserFromJson(json);
    } catch (e) {
      // If auto-generated fromJson fails, try to create User with safe defaults
      return User(
        id_pegawai: _safeInt(json['id_pegawai']),
        nama: json['nama'] as String?,
        nip: json['nip'] as String? ?? '',
        email: json['email'] as String?,
        alamat: json['alamat'] as String?,
        username: json['username'] as String? ?? '',
        id_jabatan: _safeInt(json['id_jabatan']),
        id_tmpt: _safeInt(json['id_tmpt']),
        tmpt_tugas: json['tmpt_tugas'] as String?,
        tgl_lahir: json['tgl_lahir'] as String?,
        divisi: json['divisi'] as String?,
        id_cabang: _safeInt(json['id_cabang']),
        avatar: json['avatar'] as String? ?? '',
        avatar_lokal: json['avatar_lokal'] as String?,
        kode_jam: json['kode_jam'] as String?,
        status: json['status'] as String?,
        tgl_joint: json['tgl_joint'] as String?,
        id_jadwal: json['id_jadwal'] != null
            ? _safeInt(json['id_jadwal'])
            : null,
        jenis_aturan: json['jenis_aturan'] as String? ?? '',
        tmpt_dikunjungi: json['tmpt_dikunjungi'] as String?,
        token: json['token'] as String?,
      );
    }
  }

  // Helper method to safely convert to int
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }
}
