import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../user.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final user = User.fromMap(userData);
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
      final response = await http.post(
        Uri.parse('https://absencobra.cbsguard.co.id/api/auth.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: form,
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        log(response.body, name: 'AuthNotifier.login');
        final data = json.decode(response.body);
        final user = User.fromMap(data['data'] ?? data);
        // Set token dari root level response jika ada
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          // Buat user baru dengan token
          final userWithToken = User(
            id_pegawai: user.id_pegawai,
            nama: user.nama,
            nip: user.nip,
            email: user.email,
            alamat: user.alamat,
            username: user.username,
            id_jabatan: user.id_jabatan,
            id_tmpt: user.id_tmpt,
            tmpt_tugas: user.tmpt_tugas,
            tgl_lahir: user.tgl_lahir,
            divisi: user.divisi,
            id_cabang: user.id_cabang,
            avatar: user.avatar,
            kode_jam: user.kode_jam,
            status: user.status,
            tgl_joint: user.tgl_joint,
            id_jadwal: user.id_jadwal,
            jenis_aturan: user.jenis_aturan,
            tmpt_dikunjungi: user.tmpt_dikunjungi,
            token: token,
          );
          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(userWithToken.toJson()));
          await prefs.setString('token', token);
          state = AsyncData(userWithToken);
          return userWithToken;
        } else {
          // Simpan user tanpa token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(user.toJson()));
          state = AsyncData(user);
          return user;
        }
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
    // Hapus data dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    state = const AsyncData(null);
  }
}
