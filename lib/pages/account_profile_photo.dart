import 'dart:convert';
import 'package:cobra_apps/services/applog.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/utility/camera_util.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/face_api_service.dart';
import '../services/profile_service.dart';
import '../utility/shared_prefs_util.dart';

// Account profile photo transient state
class AccountProfileState {
  final bool isCameraReady;
  final XFile? imageFile;
  final double? facePercent;
  final bool canSendAbsen;
  final String? address;
  final String uploadResponse;
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

  const AccountProfileState({
    this.isCameraReady = false,
    this.imageFile,
    this.facePercent,
    this.canSendAbsen = false,
    this.address,
    this.uploadResponse = '',
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

  AccountProfileState copyWith({
    bool? isCameraReady,
    XFile? imageFile,
    double? facePercent,
    bool? canSendAbsen,
    String? address,
    String? uploadResponse,
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
    return AccountProfileState(
      isCameraReady: isCameraReady ?? this.isCameraReady,
      imageFile: imageFile ?? this.imageFile,
      facePercent: facePercent ?? this.facePercent,
      canSendAbsen: canSendAbsen ?? this.canSendAbsen,
      address: address ?? this.address,
      uploadResponse: uploadResponse ?? this.uploadResponse,
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

class AccountProfileNotifier extends Notifier<AccountProfileState> {
  @override
  AccountProfileState build() => const AccountProfileState();

  void setCameraReady(bool v) => state = state.copyWith(isCameraReady: v);
  void setImage(XFile? f) => state = state.copyWith(imageFile: f);
  void setFacePercent(double? p) => state = state.copyWith(facePercent: p);
  void setCanSendAbsen(bool v) => state = state.copyWith(canSendAbsen: v);
  void setAddress(String? a) => state = state.copyWith(address: a);
  void setUploadResponse(String r) => state = state.copyWith(uploadResponse: r);
  void setLoading(bool v) => state = state.copyWith(isLoading: v);
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

final accountProfileProvider =
    NotifierProvider<AccountProfileNotifier, AccountProfileState>(
      () => AccountProfileNotifier(),
    );

class AccountProfilePhotoPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const AccountProfilePhotoPage({super.key, this.data});

  @override
  ConsumerState<AccountProfilePhotoPage> createState() =>
      _AccountProfilePhotoPageState();
}

class _AccountProfilePhotoPageState
    extends ConsumerState<AccountProfilePhotoPage> {
  CameraController? _cameraController;

  void _goToDashboard() {
    // stop/cleanup any camera or listeners here if needed
    // then navigate to Dashboard as root
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DashboardPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _cameraController = await CameraUtil.tryInitCamera(
        context,
        () => ref.read(accountProfileProvider.notifier).setCameraReady(true),
      );
      await _loadPrefs();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Foto Avatar',
          style: TextStyle(color: Colors.white),
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: _goToDashboard,
        // ),
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
                      ref.watch(accountProfileProvider).isCameraReady &&
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
                                    onTap: () async => await _takePictureSafe(),
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

                            // thumbnail preview at bottom-left when image captured
                            if (ref.watch(accountProfileProvider).imageFile !=
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
                                                  .watch(accountProfileProvider)
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
                                              .watch(accountProfileProvider)
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
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ],
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
      ref.read(accountProfileProvider.notifier).setImage(f);
      // Immediately upload the taken picture to faceapi endpoint
      try {
        await _uploadFace(File(f.path));
      } catch (e) {
        LogService.log(
          level: 'ERROR',
          source: 'AccountProfilePhoto',
          action: 'upload_error',
          message: 'upload error: $e',
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
        }
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'AccountProfilePhoto',
        action: 'take_picture_error',
        message: 'takePicture error: $e',
      );
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
        LogService.log(
          level: 'WARNING',
          source: 'AccountProfilePhoto',
          action: 'parse_user_error',
          message: 'Error parsing user data in _uploadFace: $e',
        );
      }
    }

    if (user == null) {
      // Fallback to defaults if user data not available
      final idPegawaiPrefs = prefs.getString('id_pegawai') ?? '1';
      final usernamePrefs = prefs.getString('username') ?? '1001';
      user = User(
        id_pegawai: int.tryParse(idPegawaiPrefs) ?? 0,
        username: usernamePrefs,
        nip: '',
        id_jabatan: 0, // default value
        id_tmpt: 0, // default value
        id_cabang: 0, // default value
        avatar: '', //avatarPrefs,
        jenis_aturan: '', // default value
      );
      LogService.log(
        level: 'INFO',
        source: 'AccountProfilePhoto',
        action: 'user_fallback',
        message: 'User data not available, using fallback values from prefs',
      );
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
    // User model is likely generated/immutable (no setter), use copyWith to update avatar
    user = user.copyWith(avatar: '');
    LogService.log(
      level: 'DEBUG',
      source: 'AccountProfilePhoto',
      action: 'user_info',
      message:
          '[AccountProfilePhoto] user.id_pegawai : ${user.id_pegawai}, user.username: ${user.username}, user.avatar: ${user.avatar}, ',
      idPegawai: user.id_pegawai,
    );
    final result = await FaceApiService.uploadFace(
      imageFile: compressedFile,
      user: user,
    );

    if (result != null) {
      if (mounted) {
        ref
            .read(accountProfileProvider.notifier)
            .setUploadResponse(result.response ?? '');
        if (result.percent != null) {
          ref
              .read(accountProfileProvider.notifier)
              .setFacePercent(result.percent);
          ref
              .read(accountProfileProvider.notifier)
              .setCanSendAbsen(result.percent! >= 65.0);
        }
      }
      LogService.log(
        level: 'INFO',
        source: 'AccountProfilePhoto',
        action: 'upload_response',
        message: 'upload response: ${result.response}',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah')));
      }

      // Load prefs and update local state
      await _loadPrefs();
      _goToDashboard();
    } else {
      if (mounted) {
        ref
            .read(accountProfileProvider.notifier)
            .setUploadResponse('Upload failed');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload gagal')));
      }
    }
  }

  // _createUserFromPrefs was unused; removed to clean up analyzer warnings.

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

        // Update profile fields in provider
        ref
            .read(accountProfileProvider.notifier)
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

        LogService.log(
          level: 'INFO',
          source: 'AccountProfilePhoto',
          action: 'profile_loaded',
          message: 'Profile data loaded and saved successfully',
        );
      } else {
        // If profile API fails, use existing data
        if (existingUser != null) {
          ref
              .read(accountProfileProvider.notifier)
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
        LogService.log(
          level: 'WARNING',
          source: 'AccountProfilePhoto',
          action: 'using_existing_prefs',
          message:
              'Using existing preference data (profile API failed or unavailable)',
        );
      }
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'AccountProfilePhoto',
        action: 'load_prefs_error',
        message: 'Error loading preferences: $e',
      );
      // Fallback to basic defaults
      ref
          .read(accountProfileProvider.notifier)
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
