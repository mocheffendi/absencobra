import 'dart:convert';
import 'dart:developer';

import 'package:absencobra/pages/absen_masuk_page.dart';
import 'package:absencobra/pages/absen_pulang_page.dart';
import 'package:absencobra/pages/create_avatar_page.dart';
import 'package:absencobra/pages/scan_masuk_page.dart';
import 'package:absencobra/pages/scan_pulang_page.dart';
import 'package:absencobra/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/attendance_provider.dart';
import '../user.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  Map<String, dynamic>? _cekModeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // only load cek_mod_absen and route according to server rules
      await _loadCekModeData();
    });
  }

  Future<void> _loadCekModeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek apakah user data ada dan avatar valid
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        log('Error parsing user data: $e');
      }
    }

    final avatar = user?.avatar;
    if (user == null || avatar == null || avatar.isEmpty) {
      log(
        'User data belum lengkap atau avatar kosong. User: $user, Avatar: $avatar',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateAvatarPage()),
      );
    } else {
      // User data lengkap dan avatar valid, lanjutkan dengan logika lainnya
      log('User data lengkap dengan avatar: $avatar');

      try {
        final data = await _cekModAbsen();
        if (data != null) {
          if (!mounted) return;
          setState(() => _cekModeData = data);
          log('Cek mode data: $data');
          // route according to rules:
          // if status true & next_mod=scan_masuk & jenis_aturan='1' -> AbsenMasukPage
          // if status true & next_mod=scan_masuk & jenis_aturan!='1' -> ScanMasukPage
          // if status true & next_mod=scan_pulang & jenis_aturan='1' -> AbsenPulangPage
          // if status true & next_mod=scan_pulang & jenis_aturan!='1' -> ScanPulangPage
          final status = data['status'] == true;
          final nextMod = (data['next_mod'] ?? '').toString();
          final jenis = (data['jenis_aturan'] ?? '').toString();

          if (status) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                if (nextMod == 'scan_masuk') {
                  if (jenis == '1') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenMasukPage(data: data),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanMasukPage(data: data),
                      ),
                    );
                  }
                } else if (nextMod == 'scan_pulang') {
                  if (jenis == '1') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenPulangPage(data: data),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanPulangPage(data: data),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unknown next_mod: $nextMod')),
                  );
                }
              } catch (e) {
                log('navigation error: $e');
              }
            });
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'No active absen')),
            );
          }
        }
        // log kept after handling
      } catch (e) {
        log('loadCekModeData error: $e');
      }
    }
  }

  // Camera/location helpers removed — this page only loads cek mode and routes

  Future<Map<String, dynamic>?> _cekModAbsen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get id_pegawai from user object instead of separate key
      final userJson = prefs.getString('user');
      User? user;
      if (userJson != null) {
        try {
          user = User.fromJson(json.decode(userJson));
        } catch (e) {
          log('Error parsing user data in _cekModAbsen: $e');
        }
      }

      if (user == null) {
        log('User data not found for _cekModAbsen');
        return null;
      }

      final idpegawai = user.id_pegawai.toString();
      log('Using idpegawai=$idpegawai for cek_mod_absen');
      final url = Uri.parse(
        '$kBaseUrl/include/cek_mod_absen.php?idpegawai=$idpegawai',
      );
      final r = await http.get(url);
      if (r.statusCode != 200) return null;
      log('cek_mod_absen response: ${r.body}');
      final parsed = json.decode(r.body) as Map<String, dynamic>;
      try {
        final idAbs = parsed['id_absen'] ?? parsed['idAbsen'];
        if (idAbs != null) {
          final idStr = idAbs.toString();
          if (idStr.isNotEmpty) {
            await prefs.setString('id_absen', idStr);
            // write to Riverpod provider; fall back to prefs if provider unavailable
            try {
              if (!mounted) return parsed;
              // We can't use ref here (not a ConsumerState) so use ProviderScope.containerOf
              final container = ProviderScope.containerOf(context);
              container.read(idAbsenProvider.notifier).setId(idStr);
            } catch (e) {
              log('set provider id_absen from absen_page failed: $e');
            }
          }
        }
      } catch (e) {
        log('save id_absen error: $e');
      }
      return parsed;
    } catch (e) {
      log('cek_mod_absen error: $e');
      return null;
    }
  }

  Future<bool> _ensureGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return p != LocationPermission.denied &&
          p != LocationPermission.deniedForever;
    } catch (e) {
      log('ensureGps error: $e');
      return false;
    }
  }

  Future<void> _startCekFlow() async {
    final okGps = await _ensureGps();
    if (!okGps) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS/izin lokasi diperlukan')),
      );
      return;
    }

    final data = await _cekModAbsen();
    if (data != null) {
      if (!mounted) return;
      setState(() => _cekModeData = data);
    }
    if (data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membaca mode absen')));
      return;
    }

    final status = data['status'] == true;

    if (!status) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'No active absen')),
      );
      return;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Use flexibleSpace to layer a frosted glass effect that blurs
        // the background image beneath the AppBar, creating an acrylic look.
        // flexibleSpace: ClipRect(
        //   child: BackdropFilter(
        //     filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        //     child: Container(
        //       color: Colors.white.withValues(
        //         alpha: 0.12,
        //       ), // tint over blurred bg
        //     ),
        //   ),
        // ),
        title: const Text('Absen'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          // reduced overlay so background remains visible through frosted elements
          Positioned.fill(
            child: Container(
              // subtle dark tint so content remains readable
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Memeriksa mode absen...'),
                    const SizedBox(height: 16),
                    if (_cekModeData != null) ...[
                      Text('next_mod: ${_cekModeData!['next_mod'] ?? ''}'),
                      Text(
                        'jenis_aturan: ${_cekModeData!['jenis_aturan'] ?? ''}',
                      ),
                      Text('status: ${_cekModeData!['status'] ?? ''}'),
                      const SizedBox(height: 8),
                      Text('${_cekModeData!['message'] ?? ''}'),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startCekFlow,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // camera/takePicture removed
}
