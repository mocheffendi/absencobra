import 'dart:convert';
import 'applog.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/absen_keluar.dart';

class AbsenKeluarBkoService {
  static Future<AbsenKeluarResponse?> sendAbsen({
    required User user,
    required Position? position,
    required File imageFile,
    required Map<String, dynamic>? cekModeData,
    required String? harimasuk,
    required String? idAbsen,
  }) async {
    try {
      final idPegawai = user.id_pegawai.toString();
      final username = user.username;
      final cabang = user.id_cabang.toString();
      final divisi = user.divisi ?? '';
      final jenisAturan = user.jenis_aturan;
      // (cekModeData != null && cekModeData['jenis_aturan'] != null)
      // ? cekModeData['jenis_aturan'].toString()
      // : user.jenis_aturan;

      final lat = position?.latitude.toString() ?? '';
      final lon = position?.longitude.toString() ?? '';

      LogService.log(
        level: 'INFO',
        source: 'AbsenKeluarBkoService',
        action: 'prepare_multipart',
        message:
            'Preparing multipart absen keluar: id=$idPegawai user=$username cabang=$cabang divisi=$divisi jenis_aturan=$jenisAturan lat=$lat lon=$lon id_absen=$idAbsen',
        idPegawai: user.id_pegawai,
      );

      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      final uri = Uri.parse('$baseUrl/api/absenkeluarapi_bko.php');
      final request = http.MultipartRequest('POST', uri);

      // Add form fields expected by the PHP
      request.fields['id_pegawai'] = idPegawai;
      request.fields['username'] = username;
      request.fields['cabang'] = cabang;
      request.fields['divisi'] = divisi;
      request.fields['latitude'] = lat;
      request.fields['longitude'] = lon;
      request.fields['jenis_aturan'] = jenisAturan;
      request.fields['harimasuk'] = harimasuk ?? '';

      if (idAbsen != null && idAbsen.isNotEmpty) {
        request.fields['id_absen'] = idAbsen;
      }

      // Attach photo file as 'foto'
      final mp = await http.MultipartFile.fromPath('foto', imageFile.path);
      request.files.add(mp);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        try {
          final parsed = json.decode(resp.body);
          LogService.log(
            level: 'INFO',
            source: 'AbsenKeluarBkoService',
            action: 'absen_response',
            message: 'absen keluar response: ${resp.body}',
            idPegawai: user.id_pegawai,
          );
          return AbsenKeluarResponse.fromJson(parsed);
        } catch (e) {
          LogService.log(
            level: 'WARNING',
            source: 'AbsenKeluarBkoService',
            action: 'absen_response_non_json',
            message: 'absen keluar non-json response: ${resp.body}',
            idPegawai: user.id_pegawai,
          );
          return AbsenKeluarResponse(message: 'Absen berhasil');
        }
      } else {
        LogService.log(
          level: 'ERROR',
          source: 'AbsenKeluarBkoService',
          action: 'absen_send_failed',
          message: 'absen send failed ${resp.statusCode} ${resp.body}',
          idPegawai: user.id_pegawai,
          data: {'status': resp.statusCode},
        );
        return AbsenKeluarResponse(
          error: 'Gagal kirim absen: ${resp.statusCode}',
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'AbsenKeluarBkoService',
        action: 'send_absen_exception',
        message: 'sendAbsen error: $e',
        idPegawai: user.id_pegawai,
      );
      return AbsenKeluarResponse(error: 'Error mengirim absen: $e');
    }
  }
}
