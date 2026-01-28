import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/face.dart';

class FaceApiService {
  static Future<FaceApiResponse?> uploadFace({
    required File imageFile,
    required User user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final uri = Uri.parse('$baseUrl/include/faceapi.php');

      final request = http.MultipartRequest('POST', uri);

      // Add user fields
      request.fields['id_pegawai'] = user.id_pegawai.toString();
      request.fields['username'] = user.username;
      request.fields['avatar'] = user.avatar;
      LogService.log(
        level: 'DEBUG',
        source: 'FaceApiService',
        action: 'upload_prepare',
        message:
            'id_pegawai: ${user.id_pegawai}, username: ${user.username}, avatar: ${user.avatar}',
        idPegawai: user.id_pegawai,
      );

      // Attach file as 'foto'
      final multipartFile = await http.MultipartFile.fromPath(
        'foto',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode == 200) {
        try {
          final parsed = json.decode(resp.body);
          double? pct;
          if (parsed is Map) {
            final raw =
                parsed['percent'] ??
                parsed['persen'] ??
                parsed['score'] ??
                parsed['match'] ??
                parsed['confidence'];
            if (raw != null) {
              pct = double.tryParse(raw.toString());
            } else if (parsed['data'] != null) {
              final d = parsed['data'];
              if (d is Map) {
                final raw2 = d['percent'] ?? d['persen'] ?? d['confidence'];
                if (raw2 != null) pct = double.tryParse(raw2.toString());
              }
            }
          }
          LogService.log(
            level: 'INFO',
            source: 'FaceApiService',
            action: 'upload_response',
            message: 'upload response: ${resp.body}',
            idPegawai: user.id_pegawai,
          );
          return FaceApiResponse(
            percent: pct,
            message: parsed['message'] ?? 'Upload berhasil',
            response: resp.body,
          );
        } catch (e) {
          LogService.log(
            level: 'WARNING',
            source: 'FaceApiService',
            action: 'parse_response_failed',
            message: 'parse upload response failed: $e',
            idPegawai: user.id_pegawai,
          );
          return FaceApiResponse(
            percent: null,
            message: 'Upload selesai',
            response: resp.body,
          );
        }
      } else {
        LogService.log(
          level: 'ERROR',
          source: 'FaceApiService',
          action: 'upload_failed',
          message:
              'upload failed status: ${resp.statusCode} body: ${resp.body}',
          idPegawai: user.id_pegawai,
          data: {'status': resp.statusCode},
        );
        return FaceApiResponse(
          error: 'Upload failed: ${resp.statusCode}',
          response: resp.body,
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'FaceApiService',
        action: 'upload_exception',
        message: '[FaceApiService] upload error: $e',
      );
      return FaceApiResponse(error: 'Upload error: $e');
    }
  }
}
