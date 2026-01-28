import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LemburService {
  static Future<List<Map<String, String>>> getLemburData(
    String idPegawai,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final uri = Uri.parse(
        '$baseUrl/api/get_tb_absen_bko.php?id_pegawai=$idPegawai',
      );
      LogService.log(
        level: 'INFO',
        source: 'LemburService',
        action: 'call_api',
        message: 'LemburService: Calling API: $uri',
      );
      final r = await http.get(uri);
      LogService.log(
        level: 'INFO',
        source: 'LemburService',
        action: 'api_status',
        message: 'LemburService: API response status: ${r.statusCode}',
      );
      LogService.log(
        level: 'INFO',
        source: 'LemburService',
        action: 'api_body',
        message: 'LemburService: API response body: ${r.body}',
      );

      if (r.statusCode == 200) {
        final body = json.decode(r.body);
        LogService.log(
          level: 'INFO',
          source: 'LemburService',
          action: 'decoded_body',
          message: 'LemburService: Decoded body: $body',
        );
        List<dynamic> items = [];
        if (body is Map && body['data'] is List) {
          items = body['data'];
        } else if (body is List) {
          items = body;
        } else if (body is Map) {
          items = [body];
        }

        LogService.log(
          level: 'INFO',
          source: 'LemburService',
          action: 'found_items',
          message: 'LemburService: Found ${items.length} items in response',
        );

        // Map to our simplified structure: tanggal (harimasuk), in (wktmasuk), out (wktpulang/wktkeluar)
        final List<Map<String, String>> rows = items.map<Map<String, String>>((
          it,
        ) {
          try {
            final m = Map<String, dynamic>.from(it as Map);
            String tanggalRaw = (m['harimasuk'] ?? m['tanggal'] ?? '')
                .toString();
            // Extract only date part (YYYY-MM-DD or DD-MM-YYYY)
            String tanggalOnly = tanggalRaw.split(' ').first;
            // Try to parse and reformat to DD-MM-YYYY
            String tanggalFormatted = tanggalOnly;
            try {
              // Accept both YYYY-MM-DD and DD-MM-YYYY
              DateTime? dt;
              if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(tanggalOnly) ||
                  tanggalOnly.contains('-')) {
                // Try YYYY-MM-DD
                dt = DateTime.tryParse(tanggalOnly);
                if (dt == null && tanggalOnly.contains('-')) {
                  // Try DD-MM-YYYY
                  final parts = tanggalOnly.split('-');
                  if (parts.length == 3) {
                    dt = DateTime.tryParse(
                      '${parts[2]}-${parts[1]}-${parts[0]}',
                    );
                  }
                }
              }
              if (dt != null) {
                tanggalFormatted =
                    '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
              }
            } catch (_) {}
            final masuk =
                (m['wktmasuk'] ?? m['jam_masuk'] ?? m['jammasuk'] ?? '')
                    .toString();
            final keluar =
                (m['wktpulang'] ??
                        m['wktkeluar'] ??
                        m['jam_keluar'] ??
                        m['jampulang'] ??
                        '')
                    .toString();
            final result = {
              'tanggal': tanggalFormatted,
              'in': masuk,
              'out': keluar,
            };
            LogService.log(
              level: 'DEBUG',
              source: 'LemburService',
              action: 'mapped_item',
              message: 'LemburService: Mapped item: $m -> $result',
            );
            return result;
          } catch (_) {
            return {'tanggal': '', 'in': '', 'out': ''};
          }
        }).toList();

        LogService.log(
          level: 'INFO',
          source: 'LemburService',
          action: 'return_rows',
          message: 'LemburService: Returning ${rows.length} mapped rows',
        );
        return rows;
      } else {
        throw Exception('Failed to load absen data');
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'LemburService',
        action: 'error',
        message: 'LemburService: Error: $e',
      );
      throw Exception('Error loading absen data: $e');
    }
  }

  static Map<String, String>? getTodaysLembur(
    List<Map<String, String>> absenData,
  ) {
    // find today's masuk and pulang (compare date part, support DD-MM-YYYY & YYYY-MM-DD)
    final today = DateTime.now();
    final todayStr1 =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'; // YYYY-MM-DD
    final todayStr2 =
        '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}'; // DD-MM-YYYY

    LogService.log(
      level: 'INFO',
      source: 'LemburService',
      action: 'find_today',
      message:
          'LemburService: Looking for today\'s data with dates: $todayStr1 or $todayStr2',
    );

    for (final r in absenData) {
      final t = r['tanggal'] ?? '';
      LogService.log(
        level: 'DEBUG',
        source: 'LemburService',
        action: 'check_record',
        message: 'LemburService: Checking record with date: $t',
      );
      if (t == todayStr1 || t == todayStr2) {
        LogService.log(
          level: 'INFO',
          source: 'LemburService',
          action: 'found_today',
          message: 'LemburService: Found today\'s record: $r',
        );
        return r;
      }
    }
    LogService.log(
      level: 'INFO',
      source: 'LemburService',
      action: 'no_today_found',
      message: 'LemburService: No today\'s record found',
    );
    return null;
  }
}
