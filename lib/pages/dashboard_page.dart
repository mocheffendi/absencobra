import 'dart:convert';

// import 'package:cobra_apps/pages/shared_prefs_page.dart'; // unused
import 'package:cobra_apps/pages/cuti_page.dart';
import 'package:cobra_apps/pages/patroli_page.dart';
import 'package:cobra_apps/pages/shared_prefs_page.dart';
import 'package:cobra_apps/providers/lembur_provider.dart';
import 'package:cobra_apps/widgets/dashboard_table_lembur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cobra_apps/pages/patrol_page.dart';
import 'package:cobra_apps/pages/account_setting_page.dart';
// import 'package:cobra_apps/pages/patrol_image_preview_page.dart';
import 'package:cobra_apps/pages/slip_gaji_page.dart';
import 'package:cobra_apps/pages/lembur_page.dart';

import 'package:cobra_apps/utility/getinitials.dart';
// import 'package:cobra_apps/utility/settings.dart';
// import 'package:cobra_apps/utility/formatters.dart';

import 'package:cobra_apps/widgets/absen_card.dart';
import 'package:cobra_apps/widgets/dashboard_menu.dart';
import 'package:cobra_apps/widgets/dashboard_table.dart';
import 'package:cobra_apps/widgets/frosted_icon_button.dart';
import 'package:cobra_apps/widgets/dashboard_table_patrol.dart';

import 'package:cobra_apps/models/user.dart';
import 'package:cobra_apps/providers/user_provider.dart';
import 'package:cobra_apps/providers/absen_provider.dart';
import 'package:cobra_apps/providers/avatar_provider.dart';
import 'package:cobra_apps/providers/patrol_provider.dart';
import 'package:cobra_apps/providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late ScrollController _controller;
  bool _atTop = true;

  // date formatting moved to shared utility: formatters.dart

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()
      ..addListener(() {
        _atTop = _controller.offset <= 0;
      });
    // Load data sequentially to improve performance
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserFromPrefs();
      await ref.read(absenProvider.notifier).loadAbsenData();
      await ref.read(lemburProvider.notifier).loadLemburData();
      await ref.read(patrolProvider.notifier).fetchPatrolHistory();
      await _loadAvatarFromPrefs();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final user = User.fromJson(json.decode(userJson));
        ref.read(userProvider.notifier).setUser(user);
      }
    } catch (_) {}
  }

  Future<void> _loadAvatarFromPrefs() async {
    try {
      // Delegate loading to the AvatarProvider so both provider state and
      // local fields remain in sync.
      await ref.read(avatarProvider.notifier).loadAvatarFromPrefs();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refreshDashboard() async {
    // Refresh data sequentially to reduce server load
    try {
      // Then load absen data
      await ref.read(absenProvider.notifier).loadAbsenData();

      // Then load lembur data
      await ref.read(lemburProvider.notifier).loadLemburData();

      // Load patrol data first (most important for dashboard)
      await ref.read(patrolProvider.notifier).fetchPatrolHistory();

      // Finally load avatar data
      await _loadAvatarFromPrefs();
    } catch (_) {
      // ignore errors during refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final avatarPath = user?.avatar ?? '';
    final patrolState = ref.watch(patrolProvider);
    // final patrolList = patrolState.patrolList;
    // final isLoadingPatrol = patrolState.isLoading;
    // final patrolError = patrolState.error;
    final absenData = ref.watch(absenProvider);
    final lemburData = ref.watch(lemburProvider);

    // Listen for user changes and reload/reset absen data when user changes
    ref.listen(authProvider, (previous, next) {
      // When user logs in (from null to user)
      if (previous?.value == null && next.hasValue && next.value != null) {
        // User logged in, load absen data
        ref.read(absenProvider.notifier).loadAbsenData();
      }
      // When user logs out (from user to null)
      else if (previous?.hasValue == true &&
          previous?.value != null &&
          (!next.hasValue || next.value == null)) {
        // User logged out, reset absen data
        ref.read(absenProvider.notifier).reset();
      }
    });

    // Debug logging for absen data
    final nama = user?.nama ?? 'User';

    return Scaffold(
      extendBody:
          true, // penting agar background terlihat di bawah BottomAppBar
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        title: Row(
          children: [
            Image.asset("assets/png/logo.png", height: 32),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingPage()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                foregroundImage: avatarPath.isNotEmpty
                    ? NetworkImage(
                        'https://panelcobra.cbsguard.co.id/assets/img/avatar/$avatarPath',
                      )
                    : null,
                child: avatarPath.isEmpty
                    ? Text(
                        getInitials(nama),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
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
            child: RefreshIndicator(
              onRefresh: () async {
                if (_atTop) return _refreshDashboard();
              },
              color: Colors.transparent,
              backgroundColor: Colors.transparent,
              child: CustomScrollView(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: AbsenCard(
                                icon: Icons.login,
                                title: "Absen Masuk",
                                color: Colors.green,
                                absenData: absenData,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: AbsenCard(
                                icon: Icons.logout,
                                title: "Absen Pulang",
                                color: Colors.red,
                                absenData: absenData,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                DashboardMenu(
                                  icon: Icons.fingerprint,
                                  label: "Absen",
                                  onTap: () =>
                                      Navigator.pushNamed(context, "/absen"),
                                ),
                                DashboardMenu(
                                  icon: Icons.bar_chart,
                                  label: "Kinerja",
                                  onTap: () =>
                                      Navigator.pushNamed(context, "/kinerja"),
                                ),
                                DashboardMenu(
                                  icon: Icons.shield,
                                  label: "Patrol",
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PatroliPage(),
                                      ),
                                    );
                                    if (result == true) {
                                      // refresh patrol history via provider
                                      ref
                                          .read(patrolProvider.notifier)
                                          .fetchPatrolHistory();
                                    }
                                  },
                                ),
                                DashboardMenu(
                                  icon: Icons.receipt_long,
                                  label: "Slip",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SlipGajiPage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                DashboardMenu(
                                  icon: Icons.access_time,
                                  label: "Lembur",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LemburPage(),
                                    ),
                                  ),
                                ),
                                // DashboardMenu(
                                //   icon: Icons.access_time,
                                //   label: "Patroli",
                                //   onTap: () => Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const PatroliPage(),
                                //     ),
                                //   ),
                                // ),
                                DashboardMenu(
                                  icon: Icons.calendar_today,
                                  label: "Izin",
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CutiPage(),
                                    ),
                                  ),
                                ),
                                // DashboardMenu(
                                //   icon: Icons.calendar_today,
                                //   label: "Pegawai",
                                //   onTap: () => Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const CreatePegawaiPage(),
                                //     ),
                                //   ),
                                // ),
                                // DashboardMenu(
                                //   icon: Icons.document_scanner,
                                //   label: "SharePref",
                                //   onTap: () => Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const SharedPrefsPage(),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Pesan status absen hari ini
                      Builder(
                        builder: (context) {
                          // Cari data absen hari ini
                          final today = DateTime.now();
                          final todayStr1 =
                              '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                          final todayStr2 =
                              '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
                          Map<String, String>? absenToday;
                          for (final r in absenData.absensi7) {
                            final t = r['tanggal'] ?? '';
                            if (t == todayStr1 || t == todayStr2) {
                              absenToday = r;
                              break;
                            }
                          }
                          String? msg;
                          if (absenToday == null ||
                              (absenToday['in'] == null ||
                                  absenToday['in']!.isEmpty)) {
                            msg = "Hari ini belum absen masuk";
                          } else if (absenToday['in'] != null &&
                              absenToday['in']!.isNotEmpty &&
                              (absenToday['out'] == null ||
                                  absenToday['out']!.isEmpty)) {
                            msg = "Hari ini belum absen pulang";
                          }
                          if (msg == null) return SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              padding: EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.pink),
                                  SizedBox(width: 8),
                                  Text(
                                    msg,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      DashboardTable(
                        title: "Absensi 7 Hari Terakhir",
                        headers: ["Tanggal", "In", "Out"],
                        absenData: absenData,
                      ),

                      DashboardTableLembur(
                        title: "Absensi lembur 7 Hari Terakhir",
                        headers: ["Tanggal", "In", "Out"],
                        lemburData: lemburData,
                      ),

                      DashboardTablePatrol(
                        title: "Data Patroli Anggota",
                        headers: ["Tanggal & Jam", "Foto Lokasi"],
                        patrolState: patrolState,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FrostedIconButton(icon: Icons.home, onPressed: () {}),
              FrostedIconButton(
                icon: Icons.bar_chart,
                onPressed: () {
                  Navigator.pushNamed(context, "/kinerja");
                },
              ),
              const SizedBox(width: 40),
              FrostedIconButton(
                icon: Icons.shield,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatrolPage()),
                  );
                  if (result == true) {
                    // refresh patrol history via provider
                    ref.read(patrolProvider.notifier).fetchPatrolHistory();
                  }

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const TestPage()),
                  // );
                },
              ),
              FrostedIconButton(
                icon: Icons.receipt_long,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SlipGajiPage()),
                  );
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const SharedPrefsPage()),
                  // );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          Navigator.pushNamed(context, "/absen");
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(Icons.fingerprint, color: Colors.white, size: 54),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
