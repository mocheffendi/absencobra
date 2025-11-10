import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/providers/page_providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../services/face_api_service.dart';
import '../services/absen_keluar_service.dart';
import '../services/location_service.dart';

// AbsenPulang page transient state
class AbsenPulangState {
  final File? imageFile;
  final bool loading;
  final String message;
  final Position? currentPosition;
  final String? address;
  final double? facePercent;
  final String? faceMessage;
  final String? avatarUrl;

  const AbsenPulangState({
    this.imageFile,
    this.loading = false,
    this.message = '',
    this.currentPosition,
    this.address,
    this.facePercent,
    this.faceMessage,
    this.avatarUrl,
  });

  AbsenPulangState copyWith({
    File? imageFile,
    bool? loading,
    String? message,
    Position? currentPosition,
    String? address,
    double? facePercent,
    String? faceMessage,
    String? avatarUrl,
  }) {
    return AbsenPulangState(
      imageFile: imageFile ?? this.imageFile,
      loading: loading ?? this.loading,
      message: message ?? this.message,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      facePercent: facePercent ?? this.facePercent,
      faceMessage: faceMessage ?? this.faceMessage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AbsenPulangNotifier extends Notifier<AbsenPulangState> {
  @override
  AbsenPulangState build() => const AbsenPulangState();

  void setImage(File? f) => state = state.copyWith(imageFile: f);
  void setLoading(bool v) => state = state.copyWith(loading: v);
  void setMessage(String m) => state = state.copyWith(message: m);
  void setCurrentPosition(Position? p) =>
      state = state.copyWith(currentPosition: p);
  void setAddress(String? a) => state = state.copyWith(address: a);
  void setFacePercent(double? p) => state = state.copyWith(facePercent: p);
  void setFaceMessage(String? m) => state = state.copyWith(faceMessage: m);
  void setAvatarUrl(String? u) => state = state.copyWith(avatarUrl: u);

  /// Reset transient AbsenPulang state (used when leaving the page)
  void clear() => state = const AbsenPulangState();
}

final absenPulangProvider =
    NotifierProvider<AbsenPulangNotifier, AbsenPulangState>(
      () => AbsenPulangNotifier(),
    );

class AbsenPulangPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const AbsenPulangPage({super.key, this.data});

  @override
  ConsumerState<AbsenPulangPage> createState() => _AbsenPulangPageState();
}

class _AbsenPulangPageState extends ConsumerState<AbsenPulangPage> {
  Future<void> _initCamera() async {}

  @override
  void dispose() {
    // Ensure any shared scan transient state is cleared when AbsenPulangPage is disposed
    try {
      ref.read(scanPulangProvider.notifier).clear();
    } catch (_) {}
    super.dispose();
  }

  void _goToDashboard() {
    log('AbsenPulangPage: _goToDashboard dipanggil');
    // Clear any scan transient state when leaving AbsenPulang so scanner doesn't keep stale data when user returns.
    try {
      ref.read(scanPulangProvider.notifier).clear();
    } catch (_) {}
    // Clear AbsenPulang page transient state (image, messages, etc.)
    try {
      ref.read(absenPulangProvider.notifier).clear();
    } catch (_) {}
    log('AbsenPulangPage: navigating to Dashboard (root)');
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
    log('AbsenPulangPage: navigation to Dashboard requested');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getLocationAndAddress();
      await _loadAvatarUrl();
      await _initCamera();
    });
  }

  Future<void> _loadAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final user = User.fromJson(json.decode(userJson));
        if (user.avatar.isNotEmpty) {
          ref
              .read(absenPulangProvider.notifier)
              .setAvatarUrl(
                'https://panelcobra.cbsguard.co.id/assets/img/avatar/${user.avatar}',
              );
        }
      } catch (e) {
        // ignore avatar error
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) {
      ref.read(absenPulangProvider.notifier).setImage(File(picked.path));
      ref.read(absenPulangProvider.notifier).setFacePercent(null);
      ref.read(absenPulangProvider.notifier).setFaceMessage('');
      await _uploadFace(File(picked.path));
    }
  }

  Future<void> _uploadFace(File imageFile) async {
    // Compress image before sending to FaceAPI
    File? compressedFile;
    try {
      final targetPath = imageFile.path.replaceFirst('.jpg', '_compressed.jpg');
      final xfile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 70,
        minWidth: 300,
        minHeight: 300,
      );
      if (xfile != null) {
        compressedFile = File(xfile.path);
      } else {
        compressedFile = imageFile;
      }
    } catch (e) {
      compressedFile = imageFile;
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        ref
            .read(absenPulangProvider.notifier)
            .setFaceMessage("Data user tidak valid");
        return;
      }
    }
    if (user == null) {
      ref
          .read(absenPulangProvider.notifier)
          .setFaceMessage("Token autentikasi tidak tersedia");
      return;
    }
    final result = await FaceApiService.uploadFace(
      imageFile: compressedFile,
      user: user,
    );
    ref.read(absenPulangProvider.notifier).setFacePercent(result?.percent);
    ref
        .read(absenPulangProvider.notifier)
        .setFaceMessage(result?.message ?? '');
  }

  Future<void> _getLocationAndAddress() async {
    final pos = await LocationService.getLocation(context: context);
    if (!mounted) return;
    ref.read(absenPulangProvider.notifier).setCurrentPosition(pos);
    if (pos != null) {
      final addr = await LocationService.resolveAddress(pos);
      if (!mounted) return;
      ref.read(absenPulangProvider.notifier).setAddress(addr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(absenPulangProvider);
    return PopScope(
      canPop: false, // Prevent automatic pop
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // If already popped, do nothing
        // Custom logic without dialog
        bool canPop = /* your condition here, e.g., */
            true; // Replace with your logic
        if (canPop) {
          // Navigator.of(context).pop(); // Manually pop if condition is met
          _goToDashboard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Absen Pulang'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToDashboard,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              state.currentPosition != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lat: ${state.currentPosition!.latitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Lon: ${state.currentPosition!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (state.address != null)
                          SizedBox(
                            width: 180,
                            child: Text(
                              state.address!,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Text(
                            'Mencari alamat...',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    )
                  : const Text(
                      'Mencari lokasi...',
                      style: TextStyle(fontSize: 12),
                    ),
              const SizedBox(height: 16),
              if (state.currentPosition != null)
                SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        state.currentPosition!.latitude,
                        state.currentPosition!.longitude,
                      ),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'cobra_apps',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              state.currentPosition!.latitude,
                              state.currentPosition!.longitude,
                            ),
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(child: Text('Memuat peta...')),
                ),
              // Keterangan field removed
              const SizedBox(height: 16),
              // Camera preview removed, restore previous layout
              const SizedBox(height: 16),
              // FaceAPI status/message above photo
              if (state.imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Builder(
                    builder: (context) {
                      if (state.facePercent == null &&
                          (state.faceMessage == null ||
                              state.faceMessage!.isEmpty)) {
                        return const Text(
                          'Sedang cek kecocokan wajah...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else if (state.facePercent != null) {
                        return Text(
                          'Wajah Cocok: ${state.facePercent!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: state.facePercent! >= 65.0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        );
                      } else if (state.faceMessage != null &&
                          state.faceMessage!.isNotEmpty) {
                        return Text(
                          state.faceMessage!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              state.imageFile == null
                  ? const Text('Belum ada foto')
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.avatarUrl != null)
                          Expanded(
                            child: Container(
                              height: 200,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                state.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 120),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Container(
                            height: 200,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.file(
                              state.imageFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil Foto'),
              ),
              const SizedBox(height: 16),
              state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed:
                          (state.imageFile != null &&
                              state.facePercent != null &&
                              state.facePercent! >= 65.0)
                          ? _submit
                          : (state.imageFile != null &&
                                state.facePercent != null &&
                                state.facePercent! < 65.0)
                          ? () {
                              ref
                                  .read(absenPulangProvider.notifier)
                                  .setImage(null);
                              ref
                                  .read(absenPulangProvider.notifier)
                                  .setFacePercent(null);
                              ref
                                  .read(absenPulangProvider.notifier)
                                  .setFaceMessage('');
                              ref
                                  .read(absenPulangProvider.notifier)
                                  .setMessage('');
                              // Also clear shared scan state so scanner restarts clean
                              try {
                                ref.read(scanPulangProvider.notifier).clear();
                              } catch (_) {}
                            }
                          : null,
                      child:
                          (state.imageFile != null &&
                              state.facePercent != null &&
                              state.facePercent! < 65.0)
                          ? const Text('Ulang Ambil Foto')
                          : const Text('Kirim Absen'),
                    ),
              const SizedBox(height: 16),
              Text(state.message, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    log('AbsenMasukPage: _submit dipanggil');
    final notifier = ref.read(absenPulangProvider.notifier);
    final state = ref.read(absenPulangProvider);

    if (state.imageFile == null) {
      notifier.setMessage("Foto wajib diisi");
      return;
    }

    notifier.setLoading(true);
    notifier.setMessage('');

    // Compress image before sending to backend
    File? compressedFile;
    try {
      final targetPath = state.imageFile!.path.replaceFirst(
        '.jpg',
        '_compressed.jpg',
      );
      final xfile = await FlutterImageCompress.compressAndGetFile(
        state.imageFile!.path,
        targetPath,
        quality: 70,
        minWidth: 300,
        minHeight: 300,
      );
      if (xfile != null) {
        compressedFile = File(xfile.path);
      } else {
        compressedFile = state.imageFile;
      }
    } catch (e) {
      compressedFile = state.imageFile;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        notifier.setMessage("Data user tidak valid");
        notifier.setLoading(false);
        return;
      }
    }

    if (user == null) {
      notifier.setMessage("Token autentikasi tidak tersedia");
      notifier.setLoading(false);
      return;
    }

    String? idAbsen =
        widget.data?['id_absen']?.toString() ??
        widget.data?['idAbsen']?.toString();
    if (idAbsen == null || idAbsen.isEmpty) {
      idAbsen = prefs.getString('id_absen');
    }
    final result = await AbsenKeluarService.sendAbsen(
      user: user,
      position: state.currentPosition,
      imageFile: compressedFile ?? state.imageFile!,
      cekModeData: widget.data,
      harimasuk: widget.data?['harimasuk']?.toString(),
      idAbsen: idAbsen,
    );

    notifier.setLoading(false);
    if (result != null && result.error != null) {
      notifier.setMessage(result.error!);
      return;
    }

    _goToDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.message ?? 'Absen berhasil')),
      );
    }
  }
}
