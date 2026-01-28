import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static Future<User?> login(Map<String, dynamic> form) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: form,
      );

      LogService.log(
        level: 'INFO',
        source: 'AuthService',
        action: 'login',
        message: 'AuthService.login - Status: ${response.statusCode}',
      );
      LogService.log(
        level: 'INFO',
        source: 'AuthService',
        action: 'login',
        message: 'AuthService.login - Response: ${response.body}',
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        LogService.log(
          level: 'DEBUG',
          source: 'AuthService',
          action: 'login',
          message: 'AuthService.login - Decoded data: $data',
        );

        // Check if login was successful by looking for success indicator
        final success = data['success'] as bool? ?? false;
        final status = data['status'] as String? ?? '';

        if (!success && status.toLowerCase() == 'error') {
          // Login failed - extract error message
          final message =
              data['message'] as String? ??
              data['error'] as String? ??
              'Login gagal';
          throw Exception(message);
        }

        // Check if we have user data
        final userData = data['data'];
        if (userData == null) {
          throw Exception('Data user tidak ditemukan dalam response');
        }

        final user = User.safeFromJson(userData as Map<String, dynamic>);

        // Set token dari root level response jika ada
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          // Buat user baru dengan token menggunakan copyWith
          final userWithToken = user.copyWith(token: token);
          return userWithToken;
        } else {
          return user;
        }
      } else {
        // HTTP error
        throw Exception('Login gagal: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // Network-level error: provide a friendly message
      LogService.log(
        level: 'ERROR',
        source: 'AuthService',
        action: 'login_network_error',
        message: 'AuthService.login network error: $e',
      );
      throw Exception(
        'Internet is disconnected, please check your internet connection',
      );
    } on http.ClientException catch (e) {
      // HTTP client error (DNS, connection refused, etc.)
      LogService.log(
        level: 'ERROR',
        source: 'AuthService',
        action: 'login_http_client_error',
        message: 'AuthService.login http client error: $e',
      );
      throw Exception(
        'Internet is disconnected, please check your internet connection',
      );
    } catch (e, st) {
      LogService.log(
        level: 'ERROR',
        source: 'AuthService',
        action: 'login_error',
        message: 'AuthService.login error: $e',
        data: {'stack': '$st'},
      );
      if (e is Exception) {
        // Preserve non-network exception messages (e.g., API returned error)
        rethrow;
      }
      throw Exception('Login error: $e');
    }
  }
}
