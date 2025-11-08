import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/face.dart';

class FaceApiService {
  static Future<FaceApiResponse?> uploadFace({
    required File imageFile,
    required User user,
  }) async {
    try {
      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/include/faceapi.php',
      );

      final request = http.MultipartRequest('POST', uri);

      // Add user fields
      request.fields['id_pegawai'] = user.id_pegawai.toString();
      request.fields['username'] = user.username;
      request.fields['avatar'] = user.avatar;
      log(
        'id_pegawai: ${user.id_pegawai}, username: ${user.username}, avatar: ${user.avatar}',
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
          log('upload response: ${resp.body}');
          return FaceApiResponse(
            percent: pct,
            message: parsed['message'] ?? 'Upload berhasil',
            response: resp.body,
          );
        } catch (e) {
          log('parse upload response failed: $e');
          return FaceApiResponse(
            percent: null,
            message: 'Upload selesai',
            response: resp.body,
          );
        }
      } else {
        log('upload failed status: ${resp.statusCode} body: ${resp.body}');
        return FaceApiResponse(
          error: 'Upload failed: ${resp.statusCode}',
          response: resp.body,
        );
      }
    } catch (e) {
      log('upload error: $e');
      return FaceApiResponse(error: 'Upload error: $e');
    }
  }
}
