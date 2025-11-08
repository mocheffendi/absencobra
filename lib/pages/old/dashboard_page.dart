import 'package:cobra_apps/pages/patrol_page.dart';
import 'package:cobra_apps/pages/shared_prefs_page.dart';
import 'package:cobra_apps/pages/slip_gaji_page.dart';
// import 'package:cobra_apps/providers/patrol_provider.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/auth_provider.dart';
// import '../providers/patrol_provider.dart';
// import '../utility/getinitials.dart';
// import 'account_setting_page.dart';
// import 'patrol_page_riverpod.dart';
// import 'shared_prefs_page.dart';
// import 'slip_gaji_page_riverpod.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Using Flutter's built-in RefreshIndicator instead of pull_to_refresh
  // Absen data
  String? _wktMasukToday;
  String? _wktPulangToday;
  final List<Map<String, String>> _absensi7 = [];
  final bool _isFetchingAbsen = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    // Refresh patrol history, avatar and absen data concurrently
    // Currently no data to refresh
  }

  @override
  Widget build(BuildContext context) {
    // final user = ref.watch(userProvider);
    // final patrolState = ref.watch(patrolProvider);
    // final patrolList = patrolState.patrolList;
    // final isLoadingPatrol = patrolState.isLoading;

    // final nama = user?.name ?? 'User';

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
        title: Row(
          children: [
            Image.asset("assets/png/logo.png", height: 32),
            const Spacer(),
            // IconButton(
            //   icon: const Icon(Icons.account_circle, color: Colors.white),
            //   tooltip: 'Account Setting',
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const AccountSettingPage()),
            //     );
            //   },
            // ),
            // const SizedBox(width: 10),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const AccountSettingPage()),
            //     );
            //   },
            //   child: CircleAvatar(
            //     radius: 18,
            //     backgroundColor: Colors.white,
            //     foregroundImage: _avatarLocalPath != null
            //         ? FileImage(File(_avatarLocalPath!)) as ImageProvider
            //         : (_avatarUrlFromPrefs != null &&
            //                   _avatarUrlFromPrefs!.isNotEmpty
            //               ? NetworkImage(_avatarUrlFromPrefs!)
            //               : null),
            //     child:
            // _avatarLocalPath == null &&
            //     (_avatarUrlFromPrefs == null ||
            //         _avatarUrlFromPrefs!.isEmpty)
            // ? Text(
            //     getInitials(nama),
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //       color: Colors.blue,
            //     ),
            //   )
            // : null,
            // ),
            // ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Colors.transparent,
        backgroundColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
            ),
            // reduced overlay so background remains visible through frosted elements
            // Positioned.fill(
            //   child: ClipRect(
            //     child: BackdropFilter(
            //       filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            //       child: Container(
            //         // subtle dark tint so content remains readable
            //         color: Colors.black.withValues(alpha: 0.12),
            //       ),
            //     ),
            //   ),
            // ),
            SafeArea(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildAbsenCard(
                              icon: Icons.login,
                              title: "Absen Masuk",
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildAbsenCard(
                              icon: Icons.logout,
                              title: "Absen Pulang",
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMenu(
                            context,
                            Icons.fingerprint,
                            "Absen",
                            () => Navigator.pushNamed(context, "/absen"),
                          ),
                          _buildMenu(
                            context,
                            Icons.bar_chart,
                            "Kinerja",
                            () => Navigator.pushNamed(context, "/kinerja"),
                          ),
                          _buildMenu(context, Icons.shield, "Patrol", () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PatrolPage(),
                              ),
                            );
                            // if (result == true) {
                            //   // refresh patrol history via provider
                            //   ref
                            //       .read(patrolProvider.notifier)
                            //       .fetchPatrolHistory();
                            // }
                          }),
                          _buildMenu(
                            context,
                            Icons.receipt_long,
                            "Slip",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SlipGajiPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pesan status absen hari ini
                    // Removed because no absen data is loaded
                    _buildTable(
                      title: "Absensi 7 Hari Terakhir",
                      headers: ["Tanggal", "In", "Out"],
                    ),

                    // Data Patroli Anggota - frosted to match app style
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                // translucent frosted header instead of solid blue
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12.0),
                                    ),
                                  ),
                                  child: const Text(
                                    "Data Patroli Anggota",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Table(
                                  border: TableBorder.symmetric(
                                    inside: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    outside: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                    ),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.04,
                                        ),
                                      ),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Tanggal & Jam",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Foto Lokasi",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // if (isLoadingPatrol)
                                    //   TableRow(
                                    //     children: [
                                    //       Padding(
                                    //         padding: EdgeInsets.all(8.0),
                                    //         child: Center(
                                    //           child:
                                    //               CircularProgressIndicator(),
                                    //         ),
                                    //       ),
                                    //       SizedBox(),
                                    //     ],
                                    //   )
                                    // else if (patrolList.isEmpty)
                                    //   TableRow(
                                    //     children: [
                                    //       Padding(
                                    //         padding: EdgeInsets.all(8.0),
                                    //         child: Text(
                                    //           "Tidak ada data",
                                    //           style: TextStyle(
                                    //             color: Colors.white,
                                    //           ),
                                    //         ),
                                    //       ),
                                    //       SizedBox(),
                                    //     ],
                                    //   )
                                    // else
                                    //   ...patrolList.map<TableRow>((row) {
                                    //     // PatrolData model used in patrol_provider
                                    //     final tanggal =
                                    //         '${row.timestamp.year}-${row.timestamp.month.toString().padLeft(2, '0')}-${row.timestamp.day.toString().padLeft(2, '0')}';
                                    //     final jam =
                                    //         '${row.timestamp.hour.toString().padLeft(2, '0')}:${row.timestamp.minute.toString().padLeft(2, '0')}';
                                    //     return TableRow(
                                    //       children: [
                                    //         Padding(
                                    //           padding: EdgeInsets.all(8.0),
                                    //           child: Text(
                                    //             jam.isNotEmpty
                                    //                 ? "$tanggal $jam"
                                    //                 : tanggal,
                                    //           ),
                                    //         ),
                                    //         Padding(
                                    //           padding: EdgeInsets.all(8.0),
                                    //           child: const Icon(
                                    //             Icons.image_not_supported,
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     );
                                    //   }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ), // efek blur lembut
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ), // frosted transparan
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ), // garis tipis di atas
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFrostedIconButton(Icons.home, onPressed: () {}),
                  _buildFrostedIconButton(Icons.camera_alt, onPressed: () {}),
                  const SizedBox(width: 40),
                  _buildFrostedIconButton(Icons.inventory, onPressed: () {}),
                  _buildFrostedIconButton(
                    Icons.description,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SharedPrefsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {},
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Absen card used in the dashboard
  Widget _buildAbsenCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    // Frosted glass absen card: blur the background beneath the card
    final borderRadius = BorderRadius.circular(15.0);
    return Container(
      // shape: RoundedRectangleBorder(borderRadius: borderRadius),
      // elevation: 4,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            height: 120,
            padding: const EdgeInsets.all(15),
            // slightly stronger tint so text remains readable over background
            // color: Colors.white.withValues(alpha: 0.10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  // Show Masuk time on Masuk card and Pulang time on Pulang card
                  title.contains('Masuk')
                      ? (_wktMasukToday ?? "__:__:__")
                      : (title.contains('Pulang')
                            ? (_wktPulangToday ?? "__:__:__")
                            : "__:__:__"),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTable({required String title, required List<String> headers}) {
    final borderRadius = BorderRadius.circular(12.0);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                // frosted header bar (translucent instead of solid blue)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Table(
                  border: TableBorder.symmetric(
                    inside: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    outside: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  children: [
                    TableRow(
                      // translucent header row to avoid solid white
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      children: headers
                          .map(
                            (h) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                h,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    // Data rows from _absensi7
                    if (_isFetchingAbsen)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          SizedBox(),
                          SizedBox(),
                        ],
                      )
                    else if (_absensi7.isEmpty)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Tidak ada data',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(),
                          SizedBox(),
                        ],
                      )
                    else
                      ..._absensi7.map(
                        (r) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                r['tanggal'] ?? '-',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                r['in'] ?? '-',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                r['out'] ?? '-',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // small helper to build frosted circular icon buttons used in bottom bar
  Widget _buildFrostedIconButton(
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onPressed,
              child: Center(child: Icon(icon, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // time formatting helper removed — not used in this read-only dashboard
}
