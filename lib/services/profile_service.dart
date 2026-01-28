// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/shared_prefs_util.dart';

class ProfileResponse {
  final String status;
  final ProfileData? data;
  final String? error;

  ProfileResponse({required this.status, this.data, this.error});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'] as String,
      data: json['data'] != null ? ProfileData.fromJson(json['data']) : null,
      error: json['error'] as String?,
    );
  }
}

class ProfileData {
  final int id_pegawai;
  final String? nama;
  final String nip;
  final String? nik;
  final String username;
  final String? alamat;
  final String? tgl_lahir;
  final String? tgl_joint;
  final String? tmpt_tugas;
  final String? divisi;
  final String? email;
  final String? telp;
  final String? jabatan;
  final String? avatar;

  ProfileData({
    required this.id_pegawai,
    this.nama,
    required this.nip,
    this.nik,
    required this.username,
    this.alamat,
    this.tgl_lahir,
    this.tgl_joint,
    this.tmpt_tugas,
    this.divisi,
    this.email,
    this.telp,
    this.jabatan,
    this.avatar,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id_pegawai: json['id_pegawai'] as int,
      nama: json['nama'] as String?,
      nip: json['nip'] as String,
      nik: json['nik'] as String?,
      username: json['username'] as String,
      alamat: json['alamat'] as String?,
      tgl_lahir: json['tgl_lahir'] as String?,
      tgl_joint: json['tgl_joint'] as String?,
      tmpt_tugas: json['tmpt_tugas'] as String?,
      divisi: json['divisi'] as String?,
      email: json['email'] as String?,
      telp: json['telp'] as String?,
      jabatan: json['jabatan'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pegawai': id_pegawai,
      'nama': nama,
      'nip': nip,
      'nik': nik,
      'username': username,
      'alamat': alamat,
      'tgl_lahir': tgl_lahir,
      'tgl_joint': tgl_joint,
      'tmpt_tugas': tmpt_tugas,
      'divisi': divisi,
      'email': email,
      'telp': telp,
      'jabatan': jabatan,
      'avatar': avatar,
    };
  }
}

class ProfileService {
  static Future<ProfileResponse?> getProfile() async {
    try {
      // Get token from SharedPreferences using SharedPrefsUtil
      final token = await SharedPrefsUtil.getPref('token') as String?;

      if (token == null || token.isEmpty) {
        return ProfileResponse(status: 'error', error: 'Token tidak ditemukan');
      }

      final prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('primary_url');
      if (baseUrl == null || baseUrl.isEmpty) {
        baseUrl = 'https://absencobra.cbsguard.co.id';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final uri = Uri.parse('$baseUrl/api/profile.php');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LogService.log(
          level: 'INFO',
          source: 'ProfileService',
          action: 'getProfile',
          message: 'Profile API response: ${response.body}',
        );
        return ProfileResponse.fromJson(data);
      } else {
        LogService.log(
          level: 'ERROR',
          source: 'ProfileService',
          action: 'getProfile_failed',
          message:
              'Profile API failed with status: ${response.statusCode}, body: ${response.body}',
        );
        return ProfileResponse(
          status: 'error',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'ProfileService',
        action: 'getProfile_exception',
        message: 'ProfileService.getProfile error: $e',
      );
      return ProfileResponse(status: 'error', error: 'Error: $e');
    }
  }
}
