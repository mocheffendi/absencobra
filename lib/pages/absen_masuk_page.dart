import 'dart:convert';
import 'dart:developer';
// import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/services/applog.dart';
import 'package:cobra_apps/widgets/gradient_button.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/user.dart';
import '../services/face_api_service.dart';
import '../services/absen_masuk_service.dart';
import '../services/location_service.dart';
// import '../services/camera_util.dart';
// import '../providers/face_api_provider.dart';
import 'package:cobra_apps/providers/page_providers.dart';

// AbsenMasuk page transient state
class AbsenMasukState {
  final File? imageFile;
  final bool loading;
  final String message;
  final Position? currentPosition;
  final String? address;
  final double? facePercent;
  final String? faceMessage;
  final String? avatarUrl;

  const AbsenMasukState({
    this.imageFile,
    this.loading = false,
    this.message = '',
    this.currentPosition,
    this.address,
    this.facePercent,
    this.faceMessage,
    this.avatarUrl,
  });

  AbsenMasukState copyWith({
    File? imageFile,
    bool? loading,
    String? message,
    Position? currentPosition,
    String? address,
    double? facePercent,
    String? faceMessage,
    String? avatarUrl,
  }) {
    return AbsenMasukState(
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

class AbsenMasukNotifier extends Notifier<AbsenMasukState> {
  @override
  AbsenMasukState build() => const AbsenMasukState();

  void setImage(File? f) => state = state.copyWith(imageFile: f);
  void setLoading(bool v) => state = state.copyWith(loading: v);
  void setMessage(String m) => state = state.copyWith(message: m);
  void setCurrentPosition(Position? p) =>
      state = state.copyWith(currentPosition: p);
  void setAddress(String? a) => state = state.copyWith(address: a);
  void setFacePercent(double? p) => state = state.copyWith(facePercent: p);
  void setFaceMessage(String? m) => state = state.copyWith(faceMessage: m);
  void setAvatarUrl(String? u) => state = state.copyWith(avatarUrl: u);

  /// Reset transient AbsenMasuk state (used when leaving the page)
  void clear() => state = const AbsenMasukState();
}

final absenMasukProvider =
    NotifierProvider<AbsenMasukNotifier, AbsenMasukState>(
      () => AbsenMasukNotifier(),
    );

class AbsenMasukPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const AbsenMasukPage({super.key, this.data});

  @override
  ConsumerState<AbsenMasukPage> createState() => _AbsenMasukPageState();
}

class _AbsenMasukPageState extends ConsumerState<AbsenMasukPage> {
  // Transient UI state is managed by absenMasukProvider

  @override
  void dispose() {
    // ref.read(scanMasukProvider.notifier).clear();
    try {
      ref.read(scanMasukProvider.notifier).clear();
    } catch (_) {}

    // Clear AbsenMasuk page transient state (image, messages, etc.)
    try {
      ref.read(absenMasukProvider.notifier).clear();
    } catch (e) {
      log('Error clearing absenMasukProvider state in _goToDashboard: $e');
    }

    // Stop scanning and clear transient scan state when disposing the page
    // try {
    //   ref.read(scanMasukProvider.notifier).setIsScanning(false);
    // } catch (_) {}
    // try {
    //   ref.read(scanMasukProvider.notifier).setLastCode(null);
    //   ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
    //   ref.read(scanMasukProvider.notifier).setValidationError(null);
    //   ref.read(scanMasukProvider.notifier).setIsValidating(false);
    //   ref.read(scanMasukProvider.notifier).setNavigated(false);
    //   ref.read(scanMasukProvider.notifier).setQrLocation(null);
    //   ref.read(scanMasukProvider.notifier).setDistanceMeters(null);
    // } catch (e) {
    //   log('Error clearing scanMasukProvider state in dispose: $e');
    // }
    super.dispose();
  }

  void _goToDashboard() {
    log('AbsenMasukPage: _goToDashboard dipanggil');
    // Clear scanMasuk transient state before leaving so QR data doesn't persist
    try {
      ref.read(scanMasukProvider.notifier).clear();
    } catch (e) {
      log('Error clearing scanMasukProvider state in _goToDashboard: $e');
    }

    // Clear AbsenMasuk page transient state (image, messages, etc.)
    try {
      ref.read(absenMasukProvider.notifier).clear();
    } catch (e) {
      log('Error clearing absenMasukProvider state in _goToDashboard: $e');
    }

    log('AbsenMasukPage: navigating to Dashboard (root)');
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
    log('AbsenMasukPage: navigation to Dashboard requested');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getLocationAndAddress();
      await _loadAvatarUrl();
    });
  }

  // _initCamera removed

  Future<void> _loadAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final user = User.fromJson(json.decode(userJson));
        if (user.avatar.isNotEmpty) {
          ref
              .read(absenMasukProvider.notifier)
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
      ref.read(absenMasukProvider.notifier).setImage(File(picked.path));
      ref.read(absenMasukProvider.notifier).setFacePercent(null);
      ref.read(absenMasukProvider.notifier).setFaceMessage('');
      await _uploadFace(File(picked.path));
    }
  }

  Future<void> _uploadFace(File imageFile) async {
    // Compress image before sending to FaceAPI
    LogService.log(
      level: 'INFO',
      source: 'absen_masuk_page',
      action: 'upload ke FaceApi',
      message: 'check berapa persen kecocokan wajah',
    );
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
            .read(absenMasukProvider.notifier)
            .setFaceMessage("Data user tidak valid");
        return;
      }
    }
    if (user == null) {
      ref
          .read(absenMasukProvider.notifier)
          .setFaceMessage("Token autentikasi tidak tersedia");
      return;
    }

    final result = await FaceApiService.uploadFace(
      imageFile: compressedFile,
      user: user,
    );
    LogService.log(
      level: 'INFO',
      source: 'absen_masuk_page',
      action: 'hasil FaceApi',
      message: 'Prosentase hasil dari FaceApi: $result',
    );
    ref.read(absenMasukProvider.notifier).setFacePercent(result?.percent);
    ref.read(absenMasukProvider.notifier).setFaceMessage(result?.message ?? '');
  }

  Future<void> _getLocationAndAddress() async {
    final pos = await LocationService.getLocation(context: context);
    if (!mounted) return;
    ref.read(absenMasukProvider.notifier).setCurrentPosition(pos);
    if (pos != null) {
      final addr = await LocationService.resolveAddress(pos);
      if (!mounted) return;
      ref.read(absenMasukProvider.notifier).setAddress(addr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(absenMasukProvider);
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
          title: const Text('Absen Masuk'),
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
              // ElevatedButton.icon(
              //   onPressed: _pickImage,
              //   icon: const Icon(Icons.camera_alt),
              //   label: const Text('Ambil Foto'),
              // ),
              gradientPillButton(
                label: 'Ambil Foto',
                onTap: _pickImage,
                icon: Icons.camera_alt,
                colors: const [Color(0xff2dd7a6), Color(0xff46a6ff)],
              ),
              const SizedBox(height: 16),
              state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: gradientPillButton(
                        label:
                            (state.imageFile != null &&
                                state.facePercent != null &&
                                state.facePercent! < 65.0)
                            ? 'Ulang Ambil Foto'
                            : 'Kirim Absen',
                        onTap:
                            (state.imageFile != null &&
                                state.facePercent != null &&
                                state.facePercent! >= 65.0)
                            ? _submit
                            : (state.imageFile != null &&
                                  state.facePercent != null &&
                                  state.facePercent! < 65.0)
                            ? () {
                                ref
                                    .read(absenMasukProvider.notifier)
                                    .setImage(null);
                                ref
                                    .read(absenMasukProvider.notifier)
                                    .setFacePercent(null);
                                ref
                                    .read(absenMasukProvider.notifier)
                                    .setFaceMessage('');
                                ref
                                    .read(absenMasukProvider.notifier)
                                    .setMessage('');
                              }
                            : null,
                        icon: Icons.send,
                        colors: const [Color(0xff2dd7a6), Color(0xff46a6ff)],
                        height: 48,
                      ),
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
    LogService.log(
      level: 'INFO',
      source: 'absen_masuk_page',
      action: 'submit absen masuk',
      message: 'submit absen masuk is call',
    );
    final notifier = ref.read(absenMasukProvider.notifier);
    final state = ref.read(absenMasukProvider);

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

    final result = await AbsenMasukService.sendAbsen(
      user: user,
      position: state.currentPosition,
      imageFile: compressedFile ?? state.imageFile!,
      cekModeData: null,
    );

    LogService.log(
      level: 'DEBUG',
      source: 'absen_masuk_page',
      action: 'hasil submit absen masuk',
      message: 'Hasil submit absen masuk : $result',
    );

    notifier.setLoading(false);
    if (result != null && result.error != null) {
      notifier.setMessage(result.error!);
      return;
    }

    LogService.log(
      level: 'INFO',
      source: 'absen_masuk_age',
      action: 'send absen sudah berhasil',
      message: 'otomatis kembali ke Dashboard',
    );

    _goToDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.message ?? 'Absen berhasil')),
      );
    }
  }
}
