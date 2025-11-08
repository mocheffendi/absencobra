import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cobra_apps/pages/absen_page.dart';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/utility/camera_util.dart';
import 'package:cobra_apps/utility/settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/absen_masuk_service.dart';
import '../services/face_api_service.dart';
import '../services/profile_service.dart';
import '../utility/shared_prefs_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// CreateAvatar page transient state
class CreateAvatarState {
  final bool isCameraReady;
  final XFile? imageFile;
  final Position? currentPosition;
  final String? address;
  final String? uploadResponse;
  final double? facePercent;
  final bool canSendAbsen;
  final Map<String, dynamic>? cekModeData;
  final bool isLoading;
  final String nama;
  final String email;
  final String nip;
  final String telp;
  final String tempatTugas;
  final String jabatan;
  final String divisi;
  final String avatarUrl;
  final String idPegawai;
  final String username;
  final String avatar;

  const CreateAvatarState({
    this.isCameraReady = false,
    this.imageFile,
    this.currentPosition,
    this.address,
    this.uploadResponse,
    this.facePercent,
    this.canSendAbsen = false,
    this.cekModeData,
    this.isLoading = false,
    this.nama = '',
    this.email = '',
    this.nip = '',
    this.telp = '',
    this.tempatTugas = '',
    this.jabatan = '',
    this.divisi = '',
    this.avatarUrl = '',
    this.idPegawai = '',
    this.username = '',
    this.avatar = '',
  });

  CreateAvatarState copyWith({
    bool? isCameraReady,
    XFile? imageFile,
    Position? currentPosition,
    String? address,
    String? uploadResponse,
    double? facePercent,
    bool? canSendAbsen,
    Map<String, dynamic>? cekModeData,
    bool? isLoading,
    String? nama,
    String? email,
    String? nip,
    String? telp,
    String? tempatTugas,
    String? jabatan,
    String? divisi,
    String? avatarUrl,
    String? idPegawai,
    String? username,
    String? avatar,
  }) {
    return CreateAvatarState(
      isCameraReady: isCameraReady ?? this.isCameraReady,
      imageFile: imageFile ?? this.imageFile,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      uploadResponse: uploadResponse ?? this.uploadResponse,
      facePercent: facePercent ?? this.facePercent,
      canSendAbsen: canSendAbsen ?? this.canSendAbsen,
      cekModeData: cekModeData ?? this.cekModeData,
      isLoading: isLoading ?? this.isLoading,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nip: nip ?? this.nip,
      telp: telp ?? this.telp,
      tempatTugas: tempatTugas ?? this.tempatTugas,
      jabatan: jabatan ?? this.jabatan,
      divisi: divisi ?? this.divisi,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      idPegawai: idPegawai ?? this.idPegawai,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
    );
  }
}

class CreateAvatarNotifier extends Notifier<CreateAvatarState> {
  @override
  CreateAvatarState build() => const CreateAvatarState();

  void setCameraReady(bool v) => state = state.copyWith(isCameraReady: v);
  void setImage(XFile? f) => state = state.copyWith(imageFile: f);
  void setCurrentPosition(Position? p) =>
      state = state.copyWith(currentPosition: p);
  void setAddress(String? a) => state = state.copyWith(address: a);
  void setUploadResponse(String? r) =>
      state = state.copyWith(uploadResponse: r);
  void setFacePercent(double? p) => state = state.copyWith(facePercent: p);
  void setCanSendAbsen(bool v) => state = state.copyWith(canSendAbsen: v);
  void setCekModeData(Map<String, dynamic>? m) =>
      state = state.copyWith(cekModeData: m);
  void setIsLoading(bool v) => state = state.copyWith(isLoading: v);
  void setProfileFields({
    String? nama,
    String? email,
    String? nip,
    String? telp,
    String? tempatTugas,
    String? jabatan,
    String? divisi,
    String? avatarUrl,
    String? idPegawai,
    String? username,
    String? avatar,
  }) {
    state = state.copyWith(
      nama: nama,
      email: email,
      nip: nip,
      telp: telp,
      tempatTugas: tempatTugas,
      jabatan: jabatan,
      divisi: divisi,
      avatarUrl: avatarUrl,
      idPegawai: idPegawai,
      username: username,
      avatar: avatar,
    );
  }
}

final createAvatarProvider =
    NotifierProvider<CreateAvatarNotifier, CreateAvatarState>(
      () => CreateAvatarNotifier(),
    );

class CreateAvatarPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const CreateAvatarPage({super.key, this.data});

  @override
  ConsumerState<CreateAvatarPage> createState() => _CreateAvatarPageState();
}

class _CreateAvatarPageState extends ConsumerState<CreateAvatarPage> {
  CameraController? _cameraController;
  // final bool _isFetchingJenis = false;
  // jenis aturan update
  // final String _selectedJenisAturan = '1';
  // update flags removed in read-only view

  void _goToDashboard() {
    // stop/cleanup any camera or listeners here if needed
    // then navigate to Dashboard as root
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardPage()),
      (route) => false,
    );
  }

  void _goToAbsenPage() {
    // stop/cleanup any camera or listeners here if needed
    // then navigate to Dashboard as root
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AbsenPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _cameraController = await CameraUtil.tryInitCamera(
        context,
        () => ref.read(createAvatarProvider.notifier).setCameraReady(true),
      );
      await _getLocation();
      await _loadPrefs();
    });
  }

  Future<void> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      ref.read(createAvatarProvider.notifier).setCurrentPosition(pos);
      // resolve address in background
      _resolveAddress(pos);
    } catch (e) {
      log('location error: $e');
    }
  }

  Future<void> _resolveAddress(Position pos) async {
    try {
      final p = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (p.isNotEmpty) {
        final pm = p.first;
        final parts = <String>[];
        if (pm.name != null && pm.name!.isNotEmpty) parts.add(pm.name!);
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
          parts.add(pm.subLocality!);
        }
        if (pm.locality != null && pm.locality!.isNotEmpty) {
          parts.add(pm.locality!);
        }
        if (pm.subAdministrativeArea != null &&
            pm.subAdministrativeArea!.isNotEmpty) {
          parts.add(pm.subAdministrativeArea!);
        }
        if (pm.administrativeArea != null &&
            pm.administrativeArea!.isNotEmpty) {
          parts.add(pm.administrativeArea!);
        }
        if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
          parts.add(pm.postalCode!);
        }
        if (pm.country != null && pm.country!.isNotEmpty) {
          parts.add(pm.country!);
        }
        final addr = parts.join(', ');
        if (!mounted) return;
        ref.read(createAvatarProvider.notifier).setAddress(addr);
      }
    } catch (e) {
      log('reverse geocode error: $e');
    }
  }

  // ignore: unused_element
  Future<Map<String, dynamic>?> _cekModAbsen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idpegawai = prefs.getString('id_pegawai') ?? '1';
      final url = Uri.parse(
        '$kBaseUrl/include/cek_mod_absen.php?idpegawai=$idpegawai',
      );
      final r = await http.get(url);
      if (r.statusCode != 200) return null;
      return json.decode(r.body) as Map<String, dynamic>;
    } catch (e) {
      log('cek_mod_absen error: $e');
      return null;
    }
  }

  // ignore: unused_element
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

  // _startCekFlow removed — logic consolidated into other flows. If needed,
  // reintroduce as a small helper that updates _cekModeData and shows SnackBars.

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          //     child: Container(color: Colors.white.withValues(alpha: 0.12)),
          //   ),
          // ),
          title: const Text(
            'Create Avatar',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToDashboard,
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
            ),

            // reduced overlay so background remains visible through frosted elements
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child:
                        ref.watch(createAvatarProvider).isCameraReady &&
                            _cameraController != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: CameraPreview(_cameraController!),
                              ),
                              // shutter centered at bottom of camera area
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 24,
                                child: Center(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async =>
                                          await _takePictureSafe(),
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // location box at top-left
                              Positioned(
                                left: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      ref
                                              .watch(createAvatarProvider)
                                              .currentPosition !=
                                          null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lat: ${ref.watch(createAvatarProvider).currentPosition!.latitude.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Lon: ${ref.watch(createAvatarProvider).currentPosition!.longitude.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (ref
                                                    .watch(createAvatarProvider)
                                                    .address !=
                                                null)
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  ref
                                                      .watch(
                                                        createAvatarProvider,
                                                      )
                                                      .address!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )
                                            else
                                              const Text(
                                                'Mencari alamat...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            if (ref
                                                    .watch(createAvatarProvider)
                                                    .uploadResponse !=
                                                null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6.0,
                                                ),
                                                child: SizedBox(
                                                  width: 180,
                                                  child: Text(
                                                    ref
                                                        .watch(
                                                          createAvatarProvider,
                                                        )
                                                        .uploadResponse!,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : const Text(
                                          'Mencari lokasi...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                              ),
                              // thumbnail preview at bottom-left when image captured
                              if (ref.watch(createAvatarProvider).imageFile !=
                                  null)
                                Positioned(
                                  left: 12,
                                  bottom: 24,
                                  child: GestureDetector(
                                    onTap: () {
                                      // show fullscreen preview
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: GestureDetector(
                                            onTap: () =>
                                                Navigator.of(context).pop(),
                                            child: Image.file(
                                              File(
                                                ref
                                                    .watch(createAvatarProvider)
                                                    .imageFile!
                                                    .path,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          File(
                                            ref
                                                .watch(createAvatarProvider)
                                                .imageFile!
                                                .path,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // show send button at bottom-right when allowed
                              if (ref.watch(createAvatarProvider).canSendAbsen)
                                Positioned(
                                  right: 12,
                                  bottom: 24,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () async => await _sendAbsen(),
                                    child: const Text('Kirim Absen'),
                                  ),
                                ),

                              // cek mode absen box at bottom-left (above thumbnail)
                              if (ref.watch(createAvatarProvider).cekModeData !=
                                  null)
                                Positioned(
                                  left: 12,
                                  bottom: 110,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'next_mod: ${ref.watch(createAvatarProvider).cekModeData!['next_mod'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'jenis_aturan: ${ref.watch(createAvatarProvider).cekModeData!['jenis_aturan'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'status: ${ref.watch(createAvatarProvider).cekModeData!['status'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if ((ref
                                                    .watch(createAvatarProvider)
                                                    .cekModeData!['message'] ??
                                                '')
                                            .toString()
                                            .isNotEmpty)
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              '${ref.watch(createAvatarProvider).cekModeData!['message']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       ElevatedButton(
                  //         onPressed: () => _startCekFlow(),
                  //         child: const Text('Cek Mode Absen'),
                  //       ),
                  //       const SizedBox(width: 12),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePictureSafe() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kamera tidak siap')));
      return;
    }
    try {
      final f = await _cameraController!.takePicture();
      ref.read(createAvatarProvider.notifier).setImage(f);
      // Immediately upload the taken picture to faceapi endpoint
      try {
        await _uploadFace(File(f.path));
      } catch (e) {
        log('upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
        }
      }
    } catch (e) {
      log('takePicture error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ambil foto: $e')));
    }
  }

  Future<void> _uploadFace(File imageFile) async {
    // Get user data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;
    if (userJson != null) {
      try {
        user = User.fromJson(json.decode(userJson));
      } catch (e) {
        log('Error parsing user data in _uploadFace: $e');
      }
    }

    if (user == null) {
      // Fallback to defaults if user data not available
      final idPegawaiPrefs = prefs.getString('id_pegawai') ?? '1';
      final usernamePrefs = prefs.getString('username') ?? '1001';
      final avatarPrefs = prefs.getString('avatar') ?? '';

      user = User(
        id_pegawai: int.tryParse(idPegawaiPrefs) ?? 1,
        username: usernamePrefs,
        nip: '1001',
        id_jabatan: 0, // default value
        id_tmpt: 0, // default value
        id_cabang: 0, // default value
        avatar: avatarPrefs,
        jenis_aturan: '', // default value
      );
      log('User data not available, using fallback values from prefs');
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengunggah foto...')));
    }

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
    final result = await FaceApiService.uploadFace(
      imageFile: compressedFile,
      user: user,
    );

    if (result != null) {
      if (mounted) {
        ref
            .read(createAvatarProvider.notifier)
            .setUploadResponse(result.response ?? '');
        if (result.percent != null) {
          ref
              .read(createAvatarProvider.notifier)
              .setFacePercent(result.percent);
          ref
              .read(createAvatarProvider.notifier)
              .setCanSendAbsen(result.percent! >= 65.0);
        }
      }
      log('upload response: ${result.response}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
      }

      // Load prefs and update local state
      await _loadPrefs();
      _goToAbsenPage();
    } else {
      if (mounted) {
        ref
            .read(createAvatarProvider.notifier)
            .setUploadResponse('Upload failed');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload gagal')));
      }
    }
  }

  Future<User> _createUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final state = ref.read(createAvatarProvider);
    return User(
      id_pegawai: int.tryParse(state.idPegawai) ?? 1,
      nama: state.nama,
      nip: state.nip,
      email: state.email,
      username: state.username,
      id_jabatan: 0, // default value
      id_tmpt: int.tryParse(prefs.getString('id_tmpt') ?? '0') ?? 0,
      divisi: state.divisi,
      id_cabang: int.tryParse(prefs.getString('cabang') ?? '0') ?? 0,
      avatar: state.avatar,
      jenis_aturan: prefs.getString('jenis_aturan') ?? '',
    );
  }

  Future<void> _loadPrefs() async {
    try {
      // First load existing preferences
      final map = await SharedPrefsUtil.loadAllPrefs();
      final existingUser = await SharedPrefsUtil.loadUser();

      // Try to get fresh profile data from API
      final profileResponse = await ProfileService.getProfile();

      if (profileResponse != null &&
          profileResponse.status == 'success' &&
          profileResponse.data != null) {
        final profileData = profileResponse.data!;

        // Create updated user object with profile data
        final updatedUser = User(
          id_pegawai: profileData.id_pegawai,
          nama: profileData.nama,
          nip: profileData.nip,
          username: profileData.username,
          alamat: profileData.alamat,
          tmpt_tugas: profileData.tmpt_tugas,
          tgl_lahir: profileData.tgl_lahir,
          divisi: profileData.divisi,
          tgl_joint: profileData.tgl_joint,
          avatar: profileData.avatar ?? '',
          token: existingUser?.token, // Keep existing token
          id_jabatan: existingUser?.id_jabatan ?? 0, // Keep existing or default
          id_tmpt: existingUser?.id_tmpt ?? 0, // Keep existing or default
          id_cabang: existingUser?.id_cabang ?? 0, // Keep existing or default
          jenis_aturan:
              existingUser?.jenis_aturan ??
              'default', // Keep existing or default
        );

        // Save updated user to SharedPreferences
        await SharedPrefsUtil.saveUser(updatedUser);

        // Update specific preferences with profile data
        if (profileData.avatar != null && profileData.avatar!.isNotEmpty) {
          await SharedPrefsUtil.setPref('avatar', profileData.avatar!);
        }
        if (profileData.nama != null && profileData.nama!.isNotEmpty) {
          await SharedPrefsUtil.setPref('nama', profileData.nama!);
        }
        if (profileData.divisi != null && profileData.divisi!.isNotEmpty) {
          await SharedPrefsUtil.setPref('divisi', profileData.divisi!);
        }
        if (profileData.tmpt_tugas != null &&
            profileData.tmpt_tugas!.isNotEmpty) {
          await SharedPrefsUtil.setPref('tmpt_tugas', profileData.tmpt_tugas!);
        }

        // Update local state variables in provider
        if (mounted) {
          ref
              .read(createAvatarProvider.notifier)
              .setProfileFields(
                nama: profileData.nama ?? '',
                email: profileData.email ?? '',
                nip: profileData.nip,
                telp: profileData.telp ?? '',
                tempatTugas: profileData.tmpt_tugas ?? '',
                jabatan: profileData.jabatan ?? '',
                divisi: profileData.divisi ?? '',
                avatarUrl: profileData.avatar ?? '',
                idPegawai: profileData.id_pegawai.toString(),
                username: profileData.username,
                avatar: profileData.avatar ?? '',
              );
        }

        log('Profile data loaded and saved successfully');
      } else {
        // If profile API fails, use existing data
        if (mounted && existingUser != null) {
          ref
              .read(createAvatarProvider.notifier)
              .setProfileFields(
                nama: existingUser.nama ?? '',
                email: existingUser.email ?? '',
                nip: existingUser.nip,
                telp: map['telp'] as String? ?? '',
                tempatTugas: map['tmpt_tugas'] as String? ?? '',
                jabatan: map['jabatan'] as String? ?? '',
                divisi: map['divisi'] as String? ?? '',
                avatarUrl: existingUser.avatar,
                idPegawai: existingUser.id_pegawai.toString(),
                username: existingUser.username,
                avatar: existingUser.avatar,
              );
        }
        log(
          'Using existing preference data (profile API failed or unavailable)',
        );
      }
    } catch (e) {
      log('Error loading preferences: $e');
      // Fallback to basic defaults
      if (mounted) {
        ref
            .read(createAvatarProvider.notifier)
            .setProfileFields(
              nama: '',
              email: '',
              nip: '',
              telp: '',
              tempatTugas: '',
              jabatan: '',
              divisi: '',
              avatarUrl: '',
              idPegawai: '1',
              username: '1001',
              avatar: '',
            );
      }
    }
  }

  Future<void> _sendAbsen() async {
    // Ensure photo exists
    final state = ref.read(createAvatarProvider);
    if (state.imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto belum diambil')));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengirim absen...')));
    }

    final user = await _createUserFromPrefs();
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
        compressedFile = File(state.imageFile!.path);
      }
    } catch (e) {
      compressedFile = File(state.imageFile!.path);
    }
    final result = await AbsenMasukService.sendAbsen(
      user: user,
      position: state.currentPosition,
      imageFile: compressedFile,
      cekModeData: state.cekModeData,
    );

    if (result != null && result.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.error!)));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.message ?? 'Absen berhasil')),
      );
      _goToDashboard();
    }
  }
}
