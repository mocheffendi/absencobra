import 'package:absencobra/pages/patrol_page.dart';
import 'package:absencobra/utility/getinitials.dart';
import 'package:absencobra/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/absen_provider.dart';
import '../providers/avatar_provider.dart';
import '../providers/patrol_provider.dart';
// import '../utility/getinitials.dart';
import '../user.dart';
import '../providers/user_provider.dart';
import 'account_setting_page.dart';
import 'patrol_image_preview_page.dart';
// import 'patrol_page_riverpod.dart';
import 'shared_prefs_page.dart';
import 'slip_gaji_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ignore: unused_field
  String? _avatarLocalPath;
  // ignore: unused_field
  String? _avatarUrlFromPrefs;

  late ScrollController _controller;
  bool _atTop = true;

  // Memoized date formatting to avoid repeated computations
  String _formatPatrolDateTime(DateTime timestamp) {
    final tanggal =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final jam =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return jam.isNotEmpty ? "$tanggal $jam" : tanggal;
  }

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
      await ref.read(patrolProvider.notifier).fetchPatrolHistory();
      await ref.read(absenProvider.notifier).loadAbsenData();
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
      final prefs = await SharedPreferences.getInstance();
      final al = prefs.getString('avatar_lokal');
      final a = prefs.getString('avatar');
      if (mounted) {
        setState(() {
          _avatarLocalPath = al;
          _avatarUrlFromPrefs = a;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshDashboard() async {
    // Refresh data sequentially to reduce server load
    try {
      // Load patrol data first (most important for dashboard)
      await ref.read(patrolProvider.notifier).fetchPatrolHistory();

      // Then load absen data
      await ref.read(absenProvider.notifier).loadAbsenData();

      // Finally load avatar data
      await _loadAvatarFromPrefs();
    } catch (_) {
      // ignore errors during refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final patrolState = ref.watch(patrolProvider);
    final patrolList = patrolState.patrolList;
    final isLoadingPatrol = patrolState.isLoading;
    final patrolError = patrolState.error;
    final absenData = ref.watch(absenProvider);
    final avatarData = ref.watch(avatarProvider);

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
                foregroundImage: avatarData.avatarLocalPath != null
                    ? FileImage(File(avatarData.avatarLocalPath!))
                          as ImageProvider
                    : (avatarData.avatarUrlFromPrefs != null &&
                              avatarData.avatarUrlFromPrefs!.isNotEmpty
                          ? NetworkImage(avatarData.avatarUrlFromPrefs!)
                          : null),
                child:
                    avatarData.avatarLocalPath == null &&
                        (avatarData.avatarUrlFromPrefs == null ||
                            avatarData.avatarUrlFromPrefs!.isEmpty)
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
                              child: _buildAbsenCard(
                                icon: Icons.login,
                                title: "Absen Masuk",
                                color: Colors.green,
                                absenData: absenData,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildAbsenCard(
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
                            _buildMenu(
                              context,
                              Icons.shield,
                              "Patrol",
                              () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PatrolPage(),
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
                      _buildTable(
                        title: "Absensi 7 Hari Terakhir",
                        headers: ["Tanggal", "In", "Out"],
                        absenData: absenData,
                      ),

                      // Data Patroli Anggota - frosted to match app style
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                  outside: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.04),
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
                                  if (isLoadingPatrol)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        SizedBox(),
                                      ],
                                    )
                                  else if (patrolError != null)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Error: $patrolError",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                        SizedBox(),
                                      ],
                                    )
                                  else if (patrolList.isEmpty)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            "Tidak ada data",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(),
                                      ],
                                    )
                                  else
                                    ...patrolList.map<TableRow>((row) {
                                      // PatrolData model used in patrol_provider
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatPatrolDateTime(
                                                    row.timestamp,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (row.status.isNotEmpty)
                                                  Text(
                                                    row.status,
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                if (row.address.isNotEmpty)
                                                  Text(
                                                    row.address,
                                                    style: TextStyle(
                                                      color: Colors.white60,
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: row.fotoUrl.isNotEmpty
                                                ? GestureDetector(
                                                    onTap: () {
                                                      final imageUrl =
                                                          '$kBaseUrl$kPatrolUrl${row.fotoUrl}';
                                                      print(
                                                        'Opening image preview: $imageUrl',
                                                      );
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              PatrolImagePreviewPage(
                                                                imageUrl:
                                                                    imageUrl,
                                                                heroTag:
                                                                    'patrol-${row.id}',
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Hero(
                                                      tag: 'patrol-${row.id}',
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          child: Image.network(
                                                            '$kBaseUrl$kPatrolUrl${row.fotoUrl}',
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => Icon(
                                                                  Icons
                                                                      .image_not_supported,
                                                                  color: Colors
                                                                      .grey,
                                                                  size: 20,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.location_on,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                          ),
                                        ],
                                      );
                                    }),
                                ],
                              ),
                            ],
                          ),
                        ),
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
              _buildFrostedIconButton(Icons.home, onPressed: () {}),
              _buildFrostedIconButton(Icons.camera_alt, onPressed: () {}),
              const SizedBox(width: 40),
              _buildFrostedIconButton(Icons.inventory, onPressed: () {}),
              _buildFrostedIconButton(
                Icons.description,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SharedPrefsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {},
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Absen card used in the dashboard
  Widget _buildAbsenCard({
    required IconData icon,
    required String title,
    required Color color,
    required AbsenData absenData,
  }) {
    // Frosted glass absen card: blur the background beneath the card
    return Container(
      // shape: RoundedRectangleBorder(borderRadius: borderRadius),
      // elevation: 4,
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
                ? (absenData.wktMasukToday ?? "__:__:__")
                : (title.contains('Pulang')
                      ? (absenData.wktPulangToday ?? "__:__:__")
                      : "__:__:__"),
            style: TextStyle(color: Colors.white),
          ),
        ],
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 28)),
            ),
          ),
          SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTable({
    required String title,
    required List<String> headers,
    required AbsenData absenData,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                inside: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
                // Data rows from absenData
                if (absenData.isLoading)
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
                else if (absenData.absensi7.isEmpty)
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
                  ...absenData.absensi7.map(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Center(child: Icon(icon, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // time formatting helper removed — not used in this read-only dashboard
}
