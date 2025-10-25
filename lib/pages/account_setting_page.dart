import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class AccountSettingPage extends ConsumerStatefulWidget {
  const AccountSettingPage({super.key});

  @override
  ConsumerState<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends ConsumerState<AccountSettingPage> {
  Future<void> _logout() async {
    // Gunakan auth provider logout yang akan membersihkan SharedPreferences dan state
    ref.read(authProvider.notifier).logout();
    // Clear user dari provider juga
    ref.read(userProvider.notifier).clearUser();
    if (!mounted) return;
    // Navigasi ke login page dan hapus semua halaman dari stack
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // flexibleSpace: ClipRect(
        //   child: BackdropFilter(
        //     filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        //     child: Container(color: Colors.white.withAlpha(30)),
        //   ),
        // ),
        title: const Text('Account Setting'),
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
            child: user == null
                ? const Center(child: Text('Tidak ada data user'))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: NetworkImage(
                            'https://panelcobra.cbsguard.co.id/assets/img/avatar/${user.avatar}',
                          ),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          user.nama ?? '-',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          user.email ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                'ID Pegawai',
                                user.id_pegawai.toString(),
                              ),
                              _buildInfoRow('Nama', user.nama ?? '-'),
                              _buildInfoRow('NIP', user.nip),
                              _buildInfoRow('Email', user.email ?? '-'),
                              _buildInfoRow('Alamat', user.alamat ?? '-'),
                              _buildInfoRow('Username', user.username),
                              _buildInfoRow(
                                'ID Jabatan',
                                user.id_jabatan.toString(),
                              ),
                              _buildInfoRow(
                                'ID Tempat',
                                user.id_tmpt.toString(),
                              ),
                              _buildInfoRow(
                                'Tempat Tugas',
                                user.tmpt_tugas ?? '-',
                              ),
                              _buildInfoRow(
                                'Tanggal Lahir',
                                user.tgl_lahir ?? '-',
                              ),
                              _buildInfoRow('Divisi', user.divisi ?? '-'),
                              _buildInfoRow(
                                'ID Cabang',
                                user.id_cabang.toString(),
                              ),
                              _buildInfoRow('Avatar', user.avatar),
                              _buildInfoRow('Kode Jam', user.kode_jam ?? '-'),
                              _buildInfoRow('Status', user.status ?? '-'),
                              _buildInfoRow(
                                'Tanggal Join',
                                user.tgl_joint ?? '-',
                              ),
                              _buildInfoRow(
                                'ID Jadwal',
                                (user.id_jadwal ?? '-').toString(),
                              ),
                              _buildInfoRow('Jenis Aturan', user.jenis_aturan),
                              _buildInfoRow(
                                'Tempat Dikunjungi',
                                user.tmpt_dikunjungi ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
