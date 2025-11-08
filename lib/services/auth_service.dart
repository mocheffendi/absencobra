import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static Future<User?> login(Map<String, dynamic> form) async {
    try {
      final response = await http.post(
        Uri.parse('https://absencobra.cbsguard.co.id/api/auth.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: form,
      );

      log(
        'AuthService.login - Status: ${response.statusCode}',
        name: 'AuthService.login',
      );
      log(
        'AuthService.login - Response: ${response.body}',
        name: 'AuthService.login',
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        log(
          'AuthService.login - Decoded data: $data',
          name: 'AuthService.login',
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

        final user = User.fromJson(userData);

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
      log('AuthService.login network error: $e', name: 'AuthService.login');
      throw Exception(
        'Internet is disconnected, please check your internet connection',
      );
    } on http.ClientException catch (e) {
      // HTTP client error (DNS, connection refused, etc.)
      log('AuthService.login http client error: $e', name: 'AuthService.login');
      throw Exception(
        'Internet is disconnected, please check your internet connection',
      );
    } catch (e, st) {
      log('AuthService.login error: $e', name: 'AuthService.login');
      log('$st', name: 'AuthService.login');
      if (e is Exception) {
        // Preserve non-network exception messages (e.g., API returned error)
        rethrow;
      }
      throw Exception('Login error: $e');
    }
  }
}
