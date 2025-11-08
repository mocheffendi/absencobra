import 'package:cobra_apps/pages/account_profile_photo.dart';
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
  void _openAccountProfilePhotoPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AccountProfilePhotoPage()));
  }

  void _openFullScreenProfilePhoto(String avatarUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenProfilePhoto(avatarUrl: avatarUrl),
      ),
    );
  }

  Widget _readonlyField(
    IconData icon,
    String label,
    String value, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPassword ? '********' : value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isPassword)
                      const Icon(
                        Icons.fingerprint,
                        color: Colors.blue,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isPassword)
            const Icon(Icons.visibility, color: Colors.yellow, size: 20),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    ref.read(authProvider.notifier).logout();
    ref.read(userProvider.notifier).clearUser();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(child: Container(color: Colors.black.withAlpha(38))),
          SafeArea(
            child: user == null
                ? const Center(
                    child: Text(
                      'Tidak ada data user',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _openFullScreenProfilePhoto(
                                      'https://panelcobra.cbsguard.co.id/assets/img/avatar/${user.avatar}',
                                    );
                                  },
                                  child: Hero(
                                    tag: 'profile-photo-hero',
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundImage: NetworkImage(
                                        'https://panelcobra.cbsguard.co.id/assets/img/avatar/${user.avatar}',
                                      ),
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openAccountProfilePhotoPage,
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 6,
                                      right: 6,
                                    ),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.cyanAccent,
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.nama ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              user.email ?? '-',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _readonlyField(
                        Icons.badge,
                        'ID Pegawai',
                        user.id_pegawai.toString(),
                      ),
                      // const SizedBox(height: 16),
                      // _readonlyField(Icons.person, 'Nama', user.nama ?? '-'),
                      const SizedBox(height: 16),
                      _readonlyField(Icons.credit_card, 'NIP', user.nip),
                      // const SizedBox(height: 16),
                      // _readonlyField(Icons.email, 'Email', user.email ?? '-'),
                      const SizedBox(height: 16),
                      _readonlyField(Icons.home, 'Alamat', user.alamat ?? '-'),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.account_circle,
                      //   'Username',
                      //   user.username,
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.work,
                      //   'ID Jabatan',
                      //   user.id_jabatan.toString(),
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.location_city,
                      //   'ID Tempat',
                      //   user.id_tmpt.toString(),
                      // ),
                      const SizedBox(height: 16),
                      _readonlyField(
                        Icons.business,
                        'Tempat Tugas',
                        user.tmpt_tugas ?? '-',
                      ),
                      const SizedBox(height: 16),
                      _readonlyField(
                        Icons.cake,
                        'Tanggal Lahir',
                        user.tgl_lahir ?? '-',
                      ),
                      const SizedBox(height: 16),
                      _readonlyField(Icons.group, 'Divisi', user.divisi ?? '-'),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.apartment,
                      //   'ID Cabang',
                      //   user.id_cabang.toString(),
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(Icons.image, 'Avatar', user.avatar),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.access_time,
                      //   'Kode Jam',
                      //   user.kode_jam ?? '-',
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.verified_user,
                      //   'Status',
                      //   user.status ?? '-',
                      // ),
                      const SizedBox(height: 16),
                      _readonlyField(
                        Icons.calendar_today,
                        'Tanggal Join',
                        user.tgl_joint ?? '-',
                      ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.schedule,
                      //   'ID Jadwal',
                      //   (user.id_jadwal ?? '-').toString(),
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.rule,
                      //   'Jenis Aturan',
                      //   user.jenis_aturan,
                      // ),
                      // const SizedBox(height: 16),
                      // _readonlyField(
                      //   Icons.place,
                      //   'Tempat Dikunjungi',
                      //   user.tmpt_dikunjungi ?? '-',
                      // ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 22),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class FullScreenProfilePhoto extends StatelessWidget {
  final String avatarUrl;
  const FullScreenProfilePhoto({super.key, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: 'profile-photo-hero',
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
