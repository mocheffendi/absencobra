import 'dart:async';
import 'dart:convert';
import 'package:cobra_apps/utility/settings.dart';
import 'package:http/http.dart' as http;
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
  final uri = Uri.parse('$kBaseApiUrl/cek_lokasi.php?qr_id=$qrId');
  try {
    final resp = await http.get(uri).timeout(timeout);
    final body = resp.body;

    if (resp.statusCode == 200) {
      try {
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
        return {
          'success': false,
          'message': 'Failed to parse response: $e',
          'statusCode': resp.statusCode,
          'raw': body,
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
  Duration timeout = const Duration(seconds: 30),
}) async {
  final uri = Uri.parse('$kBaseApiUrl/patrol_api2.php');
  try {
    var request = http.MultipartRequest('POST', uri)
      ..fields['qr_id'] = qrId
      ..fields['keterangan'] = keterangan
      ..headers['Authorization'] = 'Bearer $token';

    // Attach file
    request.files.add(await http.MultipartFile.fromPath('foto1', filePath));

    final streamed = await request.send().timeout(timeout);
    final respStr = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    try {
      final parsed = json.decode(respStr);
      if (parsed is Map<String, dynamic>) {
        return {
          'success': parsed['success'] == true,
          'message': parsed['message']?.toString() ?? '',
          'statusCode': status,
          'raw': respStr,
          'data': parsed,
        };
      }
      return {
        'success': false,
        'message': 'Invalid response format',
        'statusCode': status,
        'raw': respStr,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: $e',
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
