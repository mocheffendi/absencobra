import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/absen_masuk.dart';

class AbsenMasukService {
  static Future<AbsenMasukResponse?> sendAbsen({
    required User user,
    required Position? position,
    required File imageFile,
    required Map<String, dynamic>? cekModeData,
  }) async {
    try {
      final idPegawai = user.id_pegawai.toString();
      final username = user.username;
      final cabang = user.id_cabang.toString();
      final jenisAturan = user.jenis_aturan;
      // (cekModeData != null && cekModeData['jenis_aturan'] != null)
      // ? cekModeData['jenis_aturan'].toString()
      // : user.jenis_aturan;
      final idTmpt = user.id_tmpt.toString();
      final avatar = user.avatar;
      final lat = position?.latitude.toString() ?? '';
      final lon = position?.longitude.toString() ?? '';

      // tmpt_dikunjungi: try to inference from _cekModeData or send default list [1,2,3]
      String tmptDikunjungi = '[]';
      if (cekModeData != null && cekModeData['tmpt_dikunjungi'] != null) {
        tmptDikunjungi = cekModeData['tmpt_dikunjungi'].toString();
      } else if (cekModeData != null && cekModeData['tmpt'] != null) {
        tmptDikunjungi = json.encode(cekModeData['tmpt']);
      }
      // if still empty or equals '[]', set default [1,2,3]
      if (tmptDikunjungi.trim().isEmpty || tmptDikunjungi.trim() == '[]') {
        tmptDikunjungi = json.encode([1, 2, 3]);
      }

      LogService.log(
        level: 'INFO',
        source: 'AbsenMasukService',
        action: 'prepare_multipart',
        message:
            "Preparing multipart absen: id_pegawai=$idPegawai username=$username cabang=$cabang jenis_aturan=$jenisAturan latitude=$lat longitude=$lon id_tmpt=$idTmpt avatar=$avatar tmpt_dikunjungi=$tmptDikunjungi",
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

      final uri = Uri.parse('$baseUrl/include/absenapi.php');
      final request = http.MultipartRequest('POST', uri);

      // Add expected form fields
      request.fields['id_pegawai'] = idPegawai;
      request.fields['username'] = username;
      request.fields['cabang'] = cabang;
      request.fields['latitude'] = lat;
      request.fields['longitude'] = lon;
      request.fields['jenis_aturan'] = jenisAturan;
      request.fields['id_tmpt'] = idTmpt;
      request.fields['avatar'] = avatar;
      request.fields['tmpt_dikunjungi'] = tmptDikunjungi;

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
            source: 'AbsenMasukService',
            action: 'absen_response',
            message: 'absen response: ${resp.body}',
            idPegawai: user.id_pegawai,
          );
          return AbsenMasukResponse.fromJson(parsed);
        } catch (e) {
          LogService.log(
            level: 'WARNING',
            source: 'AbsenMasukService',
            action: 'absen_response_non_json',
            message: 'absen non-json response: ${resp.body}',
            idPegawai: user.id_pegawai,
          );
          return AbsenMasukResponse(message: 'Absen berhasil');
        }
      } else {
        LogService.log(
          level: 'ERROR',
          source: 'AbsenMasukService',
          action: 'absen_send_failed',
          message: 'absen send failed ${resp.statusCode} ${resp.body}',
          idPegawai: user.id_pegawai,
          data: {'status': resp.statusCode},
        );
        return AbsenMasukResponse(
          error: 'Gagal kirim absen: ${resp.statusCode}',
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'AbsenMasukService',
        action: 'send_absen_exception',
        message: 'sendAbsen error: $e',
        idPegawai: user.id_pegawai,
      );
      return AbsenMasukResponse(error: 'Error mengirim absen: $e');
    }
  }
}
