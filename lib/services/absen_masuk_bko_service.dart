import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/absen_masuk.dart';

class AbsenMasukBkoService {
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
      final jenisAturan =
          (cekModeData != null && cekModeData['jenis_aturan'] != null)
          ? cekModeData['jenis_aturan'].toString()
          : user.jenis_aturan;
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

      log(
        "Preparing multipart absen: id_pegawai=$idPegawai username=$username cabang=$cabang latitude=$lat longitude=$lon jenis_aturan=$jenisAturan id_tmpt=$idTmpt avatar=$avatar tmpt_dikunjungi=$tmptDikunjungi",
      );

      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/api/absenapi_bko.php',
      );
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
          log('absen response: ${resp.body}');
          return AbsenMasukResponse.fromJson(parsed);
        } catch (e) {
          log('absen non-json response: ${resp.body}');
          return AbsenMasukResponse(message: 'Absen berhasil');
        }
      } else {
        log('absen send failed ${resp.statusCode} ${resp.body}');
        return AbsenMasukResponse(
          error: 'Gagal kirim absen: ${resp.statusCode}',
        );
      }
    } catch (e) {
      log('sendAbsen error: $e');
      return AbsenMasukResponse(error: 'Error mengirim absen: $e');
    }
  }
}
