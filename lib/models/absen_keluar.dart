// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'absen_keluar.freezed.dart';
part 'absen_keluar.g.dart';

@freezed
class AbsenKeluarRequest with _$AbsenKeluarRequest {
  const factory AbsenKeluarRequest({
    required int id_pegawai,
    required String username,
    required int cabang,
    required String divisi,
    required String latitude,
    required String longitude,
    required String jenis_aturan,
    required String harimasuk,
    String? id_absen,
  }) = _AbsenKeluarRequest;

  factory AbsenKeluarRequest.fromJson(Map<String, dynamic> json) =>
      _$AbsenKeluarRequestFromJson(json);
}

@freezed
class AbsenKeluarResponse with _$AbsenKeluarResponse {
  const factory AbsenKeluarResponse({String? message, String? error}) =
      _AbsenKeluarResponse;

  factory AbsenKeluarResponse.fromJson(Map<String, dynamic> json) =>
      _$AbsenKeluarResponseFromJson(json);
}
