// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id_pegawai: (json['id_pegawai'] as num).toInt(),
  nama: json['nama'] as String?,
  nip: json['nip'] as String,
  nik: json['nik'] as String?,
  agama: json['agama'] as String?,
  telp: json['telp'] as String?,
  no_rekening: json['no_rekening'] as String?,
  email: json['email'] as String?,
  alamat: json['alamat'] as String?,
  username: json['username'] as String,
  id_jabatan: (json['id_jabatan'] as num).toInt(),
  jabatan: json['jabatan'] as String?,
  id_tmpt: (json['id_tmpt'] as num).toInt(),
  tmpt_tugas: json['tmpt_tugas'] as String?,
  tgl_lahir: json['tgl_lahir'] as String?,
  divisi: json['divisi'] as String?,
  id_cabang: (json['id_cabang'] as num).toInt(),
  cabang: json['cabang'] as String?,
  avatar: json['avatar'] as String,
  avatar_lokal: json['avatar_lokal'] as String?,
  kode_jam: json['kode_jam'] as String?,
  status: json['status'] as String?,
  tgl_joint: json['tgl_joint'] as String?,
  id_jadwal: (json['id_jadwal'] as num?)?.toInt(),
  jadwal: json['jadwal'] as String?,
  jenis_aturan: json['jenis_aturan'] as String,
  tmpt_dikunjungi: json['tmpt_dikunjungi'] as String?,
  token: json['token'] as String?,
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id_pegawai': instance.id_pegawai,
      'nama': instance.nama,
      'nip': instance.nip,
      'nik': instance.nik,
      'agama': instance.agama,
      'telp': instance.telp,
      'no_rekening': instance.no_rekening,
      'email': instance.email,
      'alamat': instance.alamat,
      'username': instance.username,
      'id_jabatan': instance.id_jabatan,
      'jabatan': instance.jabatan,
      'id_tmpt': instance.id_tmpt,
      'tmpt_tugas': instance.tmpt_tugas,
      'tgl_lahir': instance.tgl_lahir,
      'divisi': instance.divisi,
      'id_cabang': instance.id_cabang,
      'cabang': instance.cabang,
      'avatar': instance.avatar,
      'avatar_lokal': instance.avatar_lokal,
      'kode_jam': instance.kode_jam,
      'status': instance.status,
      'tgl_joint': instance.tgl_joint,
      'id_jadwal': instance.id_jadwal,
      'jadwal': instance.jadwal,
      'jenis_aturan': instance.jenis_aturan,
      'tmpt_dikunjungi': instance.tmpt_dikunjungi,
      'token': instance.token,
    };
