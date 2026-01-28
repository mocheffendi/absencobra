import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cobra_apps/utility/settings.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// dart:io not required here

/// Service helper to fetch patrol location info for a given QR id.
///
/// Returns a Map with the following keys:
/// - `success` (bool) — whether the call succeeded and server returned success
/// - `nama_tmpt` (String?) — name of the location when available
/// - `message` (String) — human readable message or error
/// - `statusCode` (int?) — HTTP status code when available
/// - `raw` (String?) — raw response body for debugging
Future<Map<String, dynamic>> fetchNamaTmptService(
  String qrId, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final prefs = await SharedPreferences.getInstance();
  String? baseUrl = prefs.getString('primary_url');
  if (baseUrl == null || baseUrl.isEmpty) {
    baseUrl = 'https://absencobra.cbsguard.co.id';
  }
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  final uri = Uri.parse('$baseUrl/api/cek_lokasi.php?qr_id=$qrId');
  try {
    final resp = await http.get(uri).timeout(timeout);
    final body = resp.body;

    if (resp.statusCode == 200) {
      try {
        if (body.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Empty response body',
            'statusCode': resp.statusCode,
            'raw': body,
            'hint': 'Empty response body from server',
          };
        }

        final parsed = json.decode(body);
        if (parsed is Map<String, dynamic>) {
          // Normalize expected fields
          return {
            'success': parsed['success'] == true,
            'nama_tmpt': parsed['nama_tmpt']?.toString(),
            'message': parsed['message']?.toString() ?? '',
            'statusCode': resp.statusCode,
            'raw': body,
          };
        } else if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          final map = Map<String, dynamic>.from(parsed.first as Map);
          return {
            'success': map['success'] == true,
            'nama_tmpt': map['nama_tmpt']?.toString(),
            'message': map['message']?.toString() ?? '',
            'statusCode': resp.statusCode,
            'raw': body,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
            'statusCode': resp.statusCode,
            'raw': body,
          };
        }
      } catch (e) {
        final snippet = body.length > 500 ? body.substring(0, 500) : body;
        final contentType = resp.headers['content-type'];
        String? hint;
        if (body.trim().isEmpty) {
          hint = 'Empty response body';
        } else if (body.trimLeft().startsWith('<')) {
          hint = 'Response looks like HTML (server error page)';
        } else if (contentType != null &&
            !contentType.contains('application/json')) {
          hint = 'Content-Type is $contentType';
        }

        return {
          'success': false,
          'message': 'Failed to parse response',
          'statusCode': resp.statusCode,
          'raw': body,
          'bodySnippet': snippet,
          'contentType': contentType,
          'hint': hint,
        };
      }
    }

    return {
      'success': false,
      'message': 'Server returned ${resp.statusCode}',
      'statusCode': resp.statusCode,
      'raw': body,
    };
  } on TimeoutException catch (e) {
    return {
      'success': false,
      'message': 'Timeout: $e',
      'statusCode': null,
      'raw': null,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: $e',
      'statusCode': null,
      'raw': null,
    };
  }
}

/// Upload patrol photo with metadata. Returns normalized map similar to fetchNamaTmptService.
Future<Map<String, dynamic>> uploadPatrolPhotoService({
  required String qrId,
  required String keterangan,
  required String filePath,
  required String token,
  bool attachFile = true,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final uri = Uri.parse('$kBaseApiUrl/patrol_api2.php');
  try {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    String idPegawai = '';
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = json.decode(userJson);
        idPegawai = (decoded['id_pegawai'] ?? decoded['idPegawai'] ?? '')
            .toString();
      } catch (_) {}
    }

    var request = http.MultipartRequest('POST', uri)
      ..fields['qr_id'] = qrId
      ..fields['keterangan'] = keterangan
      ..fields['id_pegawai'] = idPegawai;

    // Attach file only when requested and when a path is provided
    if (attachFile && filePath.isNotEmpty) {
      try {
        request.files.add(await http.MultipartFile.fromPath('foto1', filePath));
      } catch (e) {
        log('uploadPatrolPhotoService: failed to attach file: $e');
      }
    } else {
      log(
        'uploadPatrolPhotoService: skipping file attachment (attachFile=$attachFile)',
      );
    }

    // Log computed content length for debugging (may help detect oversized uploads)
    try {
      log(
        'uploadPatrolPhotoService: request contentLength=${request.contentLength}',
      );
    } catch (_) {}

    final streamed = await request.send().timeout(timeout);
    final respStr = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    // Defensive parsing: avoid throwing on empty or non-JSON responses and
    // provide helpful diagnostics for server-side failures.
    try {
      final sanitized = respStr.trim();

      log(
        'uploadPatrolPhotoService: response status=$status; length=${sanitized.length}',
      );
      if (sanitized.isEmpty) {
        final snippet = respStr.length > 500
            ? respStr.substring(0, 500)
            : respStr;
        log('uploadPatrolPhotoService: empty response body (status=$status)');
        return {
          'success': false,
          'message': 'Empty response body from server',
          'statusCode': status,
          'raw': respStr,
          'bodySnippet': snippet,
          'hint':
              'Server returned empty body; check server logs and PHP upload limits',
        };
      }

      try {
        final parsed = json.decode(sanitized);
        if (parsed is Map<String, dynamic>) {
          return {
            'success': parsed['success'] == true,
            'message': parsed['message']?.toString() ?? '',
            'statusCode': status,
            'raw': respStr,
            'data': parsed,
          };
        }
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          final map = Map<String, dynamic>.from(parsed.first as Map);
          return {
            'success': map['success'] == true,
            'message': map['message']?.toString() ?? '',
            'statusCode': status,
            'raw': respStr,
            'data': map,
          };
        }
        return {
          'success': false,
          'message': 'Invalid response format',
          'statusCode': status,
          'raw': respStr,
        };
      } on FormatException catch (e) {
        final snippet = respStr.length > 500
            ? respStr.substring(0, 500)
            : respStr;
        log('uploadPatrolPhotoService: JSON parse error: $e');
        log('Response snippet: $snippet');
        return {
          'success': false,
          'message': 'Failed to parse JSON response: ${e.message}',
          'statusCode': status,
          'raw': respStr,
          'bodySnippet': snippet,
          'hint':
              'Response not valid JSON; server may have errored (500) or returned HTML',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network/parse error: $e',
        'statusCode': status,
        'raw': respStr,
      };
    }
  } on TimeoutException catch (e) {
    return {
      'success': false,
      'message': 'Timeout: $e',
      'statusCode': null,
      'raw': null,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: $e',
      'statusCode': null,
      'raw': null,
    };
  }
}
