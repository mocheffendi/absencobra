import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/absen_keluar.dart';

class AbsenKeluarService {
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
      final jenisAturan =
          (cekModeData != null && cekModeData['jenis_aturan'] != null)
          ? cekModeData['jenis_aturan'].toString()
          : user.jenis_aturan;

      final lat = position?.latitude.toString() ?? '';
      final lon = position?.longitude.toString() ?? '';

      log(
        'Preparing multipart absen keluar: id=$idPegawai user=$username cabang=$cabang lat=$lat lon=$lon id_absen=$idAbsen',
      );

      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/include/absenkeluarapi.php',
      );
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
          log('absen keluar response: ${resp.body}');
          return AbsenKeluarResponse.fromJson(parsed);
        } catch (e) {
          log('absen keluar non-json response: ${resp.body}');
          return AbsenKeluarResponse(message: 'Absen berhasil');
        }
      } else {
        log('absen send failed ${resp.statusCode} ${resp.body}');
        return AbsenKeluarResponse(
          error: 'Gagal kirim absen: ${resp.statusCode}',
        );
      }
    } catch (e) {
      log('sendAbsen error: $e');
      return AbsenKeluarResponse(error: 'Error mengirim absen: $e');
    }
  }
}
