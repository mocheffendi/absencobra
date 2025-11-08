import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

final prefsProvider = StateProvider<Map<String, Object?>>((ref) => {});
final userPrefsProvider = StateProvider<User?>((ref) => null);

class SharedPrefsPage extends ConsumerStatefulWidget {
  const SharedPrefsPage({super.key});
  @override
  ConsumerState<SharedPrefsPage> createState() => _SharedPrefsPageState();
}

class _SharedPrefsPageState extends ConsumerState<SharedPrefsPage> {
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, Object?>{};
    for (final k in keys) {
      map[k] = prefs.get(k);
    }
    User? user;
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (_) {}
    }
    ref.read(prefsProvider.notifier).state = map;
    ref.read(userPrefsProvider.notifier).state = user;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final user = ref.watch(userPrefsProvider);
    final entries = prefs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Preferences')),
      body: RefreshIndicator(
        onRefresh: _loadPrefs,
        child: ListView(
          children: [
            if (user != null) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'User Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                title: const Text('ID Pegawai'),
                subtitle: Text(user.id_pegawai.toString()),
              ),
              if (user.nama != null)
                ListTile(title: const Text('Nama'), subtitle: Text(user.nama!)),
              ListTile(title: const Text('NIP'), subtitle: Text(user.nip)),
              if (user.email != null)
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user.email!),
                ),
              if (user.alamat != null)
                ListTile(
                  title: const Text('Alamat'),
                  subtitle: Text(user.alamat!),
                ),
              ListTile(
                title: const Text('Username'),
                subtitle: Text(user.username),
              ),
              ListTile(
                title: const Text('ID Jabatan'),
                subtitle: Text(user.id_jabatan.toString()),
              ),
              ListTile(
                title: const Text('ID Tempat'),
                subtitle: Text(user.id_tmpt.toString()),
              ),
              if (user.tmpt_tugas != null)
                ListTile(
                  title: const Text('Tempat Tugas'),
                  subtitle: Text(user.tmpt_tugas!),
                ),
              if (user.tgl_lahir != null)
                ListTile(
                  title: const Text('Tanggal Lahir'),
                  subtitle: Text(user.tgl_lahir!),
                ),
              if (user.divisi != null)
                ListTile(
                  title: const Text('Divisi'),
                  subtitle: Text(user.divisi!),
                ),
              ListTile(
                title: const Text('ID Cabang'),
                subtitle: Text(user.id_cabang.toString()),
              ),
              ListTile(
                title: const Text('Avatar'),
                subtitle: Text(user.avatar),
              ),
              // ListTile(
              //   title: const Text('Avatar_lokal'),
              //   subtitle: Text(user.avatar_lokal ?? ''),
              // ),
              if (user.kode_jam != null)
                ListTile(
                  title: const Text('Kode Jam'),
                  subtitle: Text(user.kode_jam!),
                ),
              if (user.status != null)
                ListTile(
                  title: const Text('Status'),
                  subtitle: Text(user.status!),
                ),
              if (user.tgl_joint != null)
                ListTile(
                  title: const Text('Tanggal Join'),
                  subtitle: Text(user.tgl_joint!),
                ),
              if (user.id_jadwal != null)
                ListTile(
                  title: const Text('ID Jadwal'),
                  subtitle: Text(user.id_jadwal.toString()),
                ),
              ListTile(
                title: const Text('Jenis Aturan'),
                subtitle: Text(user.jenis_aturan),
              ),
              if (user.tmpt_dikunjungi != null)
                ListTile(
                  title: const Text('Tempat Dikunjungi'),
                  subtitle: Text(user.tmpt_dikunjungi!),
                ),
              const Divider(),
            ],
            if (entries.isEmpty) const SizedBox(height: 200),
            if (entries.isEmpty) const Center(child: Text('No keys stored')),
            ...entries.map(
              (e) => ListTile(
                title: Text(e.key),
                subtitle: Text(e.value?.toString() ?? 'null'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: e.value?.toString() ?? ''),
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
