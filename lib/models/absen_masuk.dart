// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'absen_masuk.freezed.dart';
part 'absen_masuk.g.dart';

@freezed
class AbsenMasukRequest with _$AbsenMasukRequest {
  const factory AbsenMasukRequest({
    required int id_pegawai,
    required String username,
    required int cabang,
    required String latitude,
    required String longitude,
    required String jenis_aturan,
    required int id_tmpt,
    required String avatar,
    required String tmpt_dikunjungi,
  }) = _AbsenMasukRequest;

  factory AbsenMasukRequest.fromJson(Map<String, dynamic> json) =>
      _$AbsenMasukRequestFromJson(json);
}

@freezed
class AbsenMasukResponse with _$AbsenMasukResponse {
  const factory AbsenMasukResponse({String? message, String? error}) =
      _AbsenMasukResponse;

  factory AbsenMasukResponse.fromJson(Map<String, dynamic> json) =>
      _$AbsenMasukResponseFromJson(json);
}
