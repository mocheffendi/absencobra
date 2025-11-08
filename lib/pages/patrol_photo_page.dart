import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// network and settings are handled by services
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/services/patrol_service.dart';
import 'package:cobra_apps/providers/patrol_provider.dart';

class PatrolPhotoState {
  final File? imageFile;
  final bool loading;
  final String message;
  final String? namaTmpt;
  final bool loadingNama;
  final bool namaValid;

  const PatrolPhotoState({
    this.imageFile,
    this.loading = false,
    this.message = '',
    this.namaTmpt,
    this.loadingNama = true,
    this.namaValid = false,
  });

  PatrolPhotoState copyWith({
    File? imageFile,
    bool? loading,
    String? message,
    String? namaTmpt,
    bool? loadingNama,
    bool? namaValid,
  }) {
    return PatrolPhotoState(
      imageFile: imageFile ?? this.imageFile,
      loading: loading ?? this.loading,
      message: message ?? this.message,
      namaTmpt: namaTmpt ?? this.namaTmpt,
      loadingNama: loadingNama ?? this.loadingNama,
      namaValid: namaValid ?? this.namaValid,
    );
  }
}

class PatrolPhotoNotifier extends Notifier<PatrolPhotoState> {
  @override
  PatrolPhotoState build() => const PatrolPhotoState();

  void setLoading(bool v) => state = state.copyWith(loading: v);
  void setMessage(String m) => state = state.copyWith(message: m);
  void setImage(File? f) => state = state.copyWith(imageFile: f);
  void setNamaTmpt(String? n) => state = state.copyWith(namaTmpt: n);
  void setLoadingNama(bool v) => state = state.copyWith(loadingNama: v);
  void setNamaValid(bool v) => state = state.copyWith(namaValid: v);
  void clear() => state = const PatrolPhotoState();
}

final patrolPhotoProvider =
    NotifierProvider<PatrolPhotoNotifier, PatrolPhotoState>(
      () => PatrolPhotoNotifier(),
    );

class PatrolPhotoPage extends ConsumerStatefulWidget {
  final String qrId;
  const PatrolPhotoPage({super.key, required this.qrId});

  @override
  ConsumerState<PatrolPhotoPage> createState() => _PatrolPhotoPageState();
}

class _PatrolPhotoPageState extends ConsumerState<PatrolPhotoPage> {
  final TextEditingController _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Defer provider modifications until after the first frame so we don't
    // attempt to write to providers while the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchNamaTmpt();
    });
  }

  Future<void> fetchNamaTmpt() async {
    log('fetchNamaTmpt called');
    // Outer guard to catch any synchronous exceptions that might occur before
    // the inner network try/catch (helps debug why inner logs may not appear).
    try {
      ref.read(patrolPhotoProvider.notifier).setLoadingNama(true);
      ref.read(patrolPhotoProvider.notifier).setNamaValid(false);
      ref.read(patrolPhotoProvider.notifier).setNamaTmpt(null);
      ref.read(patrolPhotoProvider.notifier).setMessage('');

      log('About to enter network try block');
      // Use the centralized service for network logic.
      final result = await fetchNamaTmptService(widget.qrId);
      log('fetchNamaTmpt service result: $result');

      if (result['success'] == true) {
        ref.read(patrolPhotoProvider.notifier).setNamaTmpt(result['nama_tmpt']);
        ref.read(patrolPhotoProvider.notifier).setNamaValid(true);
      } else {
        final msg = result['message']?.toString() ?? 'Lokasi tidak ditemukan';
        ref.read(patrolPhotoProvider.notifier).setNamaTmpt(msg);
        ref.read(patrolPhotoProvider.notifier).setNamaValid(false);
      }
    } catch (e, st) {
      // Catches synchronous errors before the network try block
      log('fetchNamaTmpt outer error: $e');
      log(st.toString());
      ref.read(patrolPhotoProvider.notifier).setNamaTmpt('Gagal cek lokasi');
      ref.read(patrolPhotoProvider.notifier).setNamaValid(false);
    } finally {
      // Ensure we always clear the loading flag so the spinner stops
      ref.read(patrolPhotoProvider.notifier).setLoadingNama(false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      ref.read(patrolPhotoProvider.notifier).setImage(File(picked.path));
    }
  }

  Future<void> _submit() async {
    final state = ref.read(patrolPhotoProvider);
    if (_keteranganController.text.isEmpty || state.imageFile == null) {
      ref
          .read(patrolPhotoProvider.notifier)
          .setMessage("Keterangan dan foto wajib diisi");
      return;
    }

    ref.read(patrolPhotoProvider.notifier).setLoading(true);
    ref.read(patrolPhotoProvider.notifier).setMessage('');

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        ref
            .read(patrolPhotoProvider.notifier)
            .setMessage("Data user tidak valid");
        ref.read(patrolPhotoProvider.notifier).setLoading(false);
        return;
      }
    }

    if (user == null || user.token == null || user.token!.isEmpty) {
      ref
          .read(patrolPhotoProvider.notifier)
          .setMessage("Token autentikasi tidak tersedia");
      ref.read(patrolPhotoProvider.notifier).setLoading(false);
      return;
    }

    final token = user.token!;

    final result = await uploadPatrolPhotoService(
      qrId: widget.qrId,
      keterangan: _keteranganController.text,
      filePath: state.imageFile!.path,
      token: token,
    );

    ref.read(patrolPhotoProvider.notifier).setLoading(false);
    ref
        .read(patrolPhotoProvider.notifier)
        .setMessage(result['message'] ?? 'Terjadi kesalahan');

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: const Text("Patroli berhasil!")));
      // Reset provider state so the form is clean for the next patrol
      try {
        ref.read(patrolPhotoProvider.notifier).clear();
        // Also ensure the global patrol provider stops processing so scanning
        // continues correctly when user returns to the Patrol page.
        try {
          ref.read(patrolProvider.notifier).setProcessingScan(false);
          ref.read(patrolProvider.notifier).setScanning(false);
        } catch (_) {}
      } catch (_) {}
      Navigator.pop(context, true); // agar dashboard refresh
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    // Ensure provider state is cleared when the page is popped/back pressed
    try {
      ref.read(patrolPhotoProvider.notifier).clear();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patrolPhotoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Foto & Submit Patroli')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            state.loadingNama
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Cek lokasi...'),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      state.namaTmpt != null
                          ? 'Lokasi: ${state.namaTmpt}'
                          : 'Lokasi tidak ditemukan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: state.namaValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
            TextField(
              controller: _keteranganController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
            const SizedBox(height: 16),
            state.imageFile == null
                ? const Text('Belum ada foto')
                : Image.file(state.imageFile!, height: 200),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
            ),
            const SizedBox(height: 16),
            state.loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: state.namaValid ? _submit : null,
                    child: const Text('Kirim Patroli'),
                  ),
            const SizedBox(height: 16),
            Text(state.message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
