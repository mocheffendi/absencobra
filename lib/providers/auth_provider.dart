import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:cobra_apps/utility/avatar_utils.dart';
import 'package:cobra_apps/providers/avatar_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Cek apakah ada data user yang tersimpan di SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson != null && token != null && token.isNotEmpty) {
      try {
        final userData = json.decode(userJson);
        final user = User.fromJson(userData);
        // Pastikan user memiliki token yang valid
        if (user.token == token) {
          log(
            'User session restored from SharedPreferences',
            name: 'AuthNotifier.build',
          );
          return user;
        }
      } catch (e) {
        log('Error restoring user session: $e', name: 'AuthNotifier.build');
        // Jika ada error, bersihkan data yang tidak valid
        await prefs.remove('user');
        await prefs.remove('token');
      }
    }

    return null;
  }

  Future<User?> login(Map<String, dynamic> form) async {
    state = const AsyncLoading();
    try {
      final user = await AuthService.login(form);

      if (user != null) {
        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(user.toJson()));

        // Try to download and save avatar locally so UI can show it immediately
        try {
          await downloadAndSaveAvatar(user.avatar, user.id_pegawai);
          // Refresh avatar provider so UI updates immediately after login
          try {
            await ref.read(avatarProvider.notifier).loadAvatarFromPrefs();
          } catch (_) {
            // ignore provider reload errors
          }
        } catch (_) {
          // ignore avatar download errors
        }
        // Simpan token jika ada
        if (user.token != null && user.token!.isNotEmpty) {
          await prefs.setString('token', user.token!);
        }

        state = AsyncData(user);
        return user;
      } else {
        state = AsyncError('Login gagal', StackTrace.current);
        return null;
      }
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return null;
    }
  }

  void logout() async {
    // Reset all user-related providers before clearing auth data
    _resetUserRelatedProviders();

    // Hapus data dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    state = const AsyncData(null);
  }

  void _resetUserRelatedProviders() {
    // Reset absen provider to initial state
    try {
      // We can't directly access other providers here, but we can invalidate them
      // by calling their reset methods if they exist, or by using ref.invalidate
      // However, since we're in a Notifier, we need to handle this differently
    } catch (e) {
      log(
        'Error resetting providers: $e',
        name: 'AuthNotifier._resetUserRelatedProviders',
      );
    }
  }
}
