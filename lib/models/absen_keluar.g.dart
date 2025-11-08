// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absen_keluar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AbsenKeluarRequestImpl _$$AbsenKeluarRequestImplFromJson(
  Map<String, dynamic> json,
) => _$AbsenKeluarRequestImpl(
  id_pegawai: (json['id_pegawai'] as num).toInt(),
  username: json['username'] as String,
  cabang: (json['cabang'] as num).toInt(),
  divisi: json['divisi'] as String,
  latitude: json['latitude'] as String,
  longitude: json['longitude'] as String,
  jenis_aturan: json['jenis_aturan'] as String,
  harimasuk: json['harimasuk'] as String,
  id_absen: json['id_absen'] as String?,
);

Map<String, dynamic> _$$AbsenKeluarRequestImplToJson(
  _$AbsenKeluarRequestImpl instance,
) => <String, dynamic>{
  'id_pegawai': instance.id_pegawai,
  'username': instance.username,
  'cabang': instance.cabang,
  'divisi': instance.divisi,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'jenis_aturan': instance.jenis_aturan,
  'harimasuk': instance.harimasuk,
  'id_absen': instance.id_absen,
};

_$AbsenKeluarResponseImpl _$$AbsenKeluarResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AbsenKeluarResponseImpl(
  message: json['message'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$AbsenKeluarResponseImplToJson(
  _$AbsenKeluarResponseImpl instance,
) => <String, dynamic>{'message': instance.message, 'error': instance.error};
