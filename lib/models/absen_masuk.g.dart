// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absen_masuk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AbsenMasukRequestImpl _$$AbsenMasukRequestImplFromJson(
  Map<String, dynamic> json,
) => _$AbsenMasukRequestImpl(
  id_pegawai: (json['id_pegawai'] as num).toInt(),
  username: json['username'] as String,
  cabang: (json['cabang'] as num).toInt(),
  latitude: json['latitude'] as String,
  longitude: json['longitude'] as String,
  jenis_aturan: json['jenis_aturan'] as String,
  id_tmpt: (json['id_tmpt'] as num).toInt(),
  avatar: json['avatar'] as String,
  tmpt_dikunjungi: json['tmpt_dikunjungi'] as String,
);

Map<String, dynamic> _$$AbsenMasukRequestImplToJson(
  _$AbsenMasukRequestImpl instance,
) => <String, dynamic>{
  'id_pegawai': instance.id_pegawai,
  'username': instance.username,
  'cabang': instance.cabang,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'jenis_aturan': instance.jenis_aturan,
  'id_tmpt': instance.id_tmpt,
  'avatar': instance.avatar,
  'tmpt_dikunjungi': instance.tmpt_dikunjungi,
};

_$AbsenMasukResponseImpl _$$AbsenMasukResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AbsenMasukResponseImpl(
  message: json['message'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$$AbsenMasukResponseImplToJson(
  _$AbsenMasukResponseImpl instance,
) => <String, dynamic>{'message': instance.message, 'error': instance.error};
