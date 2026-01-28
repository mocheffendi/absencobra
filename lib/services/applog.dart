import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LogService {
  /// Dapatkan endpoint dari SharedPreferences `primary_url`, fallback ke default.
  static Future<String> _getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('primary_url');
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = 'https://absencobra.cbsguard.co.id';
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return '$baseUrl/api/applogapi.php';
  }

  /// Ambil device ID sederhana
  static Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id;
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      return info.deviceId;
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      return info.systemGUID ?? 'unknown-mac';
    } else {
      return 'unknown-device';
    }
  }

  /// Kirim log ke server
  static Future<void> log({
    required String level, // INFO, ERROR, WARNING, DEBUG
    required String source, // Page / Feature
    required String action, // Action name
    required String message, // Pesan log
    int? idPegawai, // ID pegawai
    Map<String, dynamic>? data, // Data tambahan
    // String appVersion = flutter.versionName,
    String appVersion = '2.0.5',
    String platform = 'Android',
  }) async {
    try {
      final deviceId = await _getDeviceId();

      // Format timestamp as YYYY-MM-DD HH:MM:SS in UTC+7 (Asia/Jakarta)
      // Use UTC then add 7 hours to ensure consistent timezone across devices
      final nowUtc = DateTime.now().toUtc();
      final dt = nowUtc.add(const Duration(hours: 7));
      String _two(int n) => n.toString().padLeft(2, '0');
      final logTime =
          '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';

      // Determine id_pegawai: prefer provided argument; otherwise read from stored user JSON
      String? finalIdPegawai;
      if (idPegawai != null) {
        finalIdPegawai = idPegawai.toString();
      } else {
        try {
          final _prefs = await SharedPreferences.getInstance();
          final userJson = _prefs.getString('user');
          if (userJson != null && userJson.isNotEmpty) {
            final decoded = json.decode(userJson);
            if (decoded is Map) {
              finalIdPegawai =
                  (decoded['id_pegawai'] ??
                          decoded['idPegawai'] ??
                          decoded['id'])
                      ?.toString();
            }
          }
        } catch (_) {
          // ignore parse errors and leave finalIdPegawai null
        }
      }

      final payload = {
        "log_time": logTime,
        "level": level,
        "source": source,
        "action": action,
        "message": message,
        "data": data,
        "device_id": deviceId,
        // id_pegawai as string when available
        "id_pegawai": finalIdPegawai,
        "app_version": appVersion,
        "platform": platform,
      };

      developer.log(
        'LogService.log - Payload: ${jsonEncode(payload)}',
        name: 'LogService',
        level: 800, // INFO level
      );

      final endpoint = await _getEndpoint();

      developer.log(
        'LogService.log - endpoint: $endpoint',
        name: 'LogService',
        level: 800, // INFO level
      );

      final r = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (r.statusCode != 200) {
        developer.log(
          'LogService.log - HTTP error status: ${r.statusCode} - body: ${r.body}',
          name: 'LogService',
          level: 1000,
        );
      } else {
        try {
          final respJson = json.decode(r.body);
          final status = respJson['status'];
          if (status is String) {
            if (status.toLowerCase() != 'ok') {
              developer.log(
                'LogService.log - unexpected status value: ${respJson['status']}',
                name: 'LogService',
                level: 1000,
              );
            }
          } else if (status is bool) {
            if (status != true) {
              developer.log(
                'LogService.log - unexpected status boolean: $status',
                name: 'LogService',
                level: 1000,
              );
            }
          } else if (status == null) {
            developer.log(
              'LogService.log - missing status field in response: ${r.body}',
              name: 'LogService',
              level: 1000,
            );
          }
        } catch (e) {
          developer.log(
            'LogService.log - error parsing response: $e',
            name: 'LogService',
            level: 1000,
          );
        }
      }
    } catch (e) {
      // Logging tidak boleh bikin app crash
      debugPrint("LogService error: $e");
    }
  }
}
