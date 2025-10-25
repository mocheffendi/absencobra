import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:absencobra/pages/absen_page.dart';
import 'package:absencobra/pages/dashboard_page.dart';
import 'package:absencobra/utility/file_utils_io.dart';
import 'package:absencobra/utility/settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateAvatarPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  const CreateAvatarPage({super.key, this.data});

  @override
  State<CreateAvatarPage> createState() => _CreateAvatarPageState();
}

class _CreateAvatarPageState extends State<CreateAvatarPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  XFile? _imageFile;
  Position? _currentPosition;
  String? _address;
  String? _uploadResponse;
  // ignore: unused_field
  double? _facePercent;
  bool _canSendAbsen = false;
  Map<String, dynamic>? _cekModeData;

  DateTime? _tanggalLahir;
  DateTime? _tanggalBergabung;
  // All fields are read-only now; no update-in-progress flag required.

  // Data tambahan
  String nip = '';
  String jabatan = '';
  String telp = '';
  String tempatTugas = '';
  String site = '';
  String lokasi = '';
  String divisi = '';
  String nama = '';
  String email = '';
  String avatarUrl = '';

  // General-purpose loading (used for operations like avatar upload)
  bool isLoading = false;
  // Network fetch flags: show CircularProgress only when these are true
  // ignore: unused_field
  bool _isFetchingProfile = false;
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
      await _tryInitCamera();
      await _getLocation();
    });
  }

  Future<void> _tryInitCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.isNotEmpty
            ? cameras.first
            : throw CameraException('NoCamera', 'No cameras found'),
      );
      _cameraController = CameraController(front, ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } on CameraException catch (e) {
      log('CameraException: ${e.code} ${e.description}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal akses kamera: ${e.code}')));
    } catch (e) {
      log('camera init error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal inisialisasi kamera')));
    }
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
      setState(() => _currentPosition = pos);
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
        setState(() => _address = addr);
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
            Positioned.fill(
              child: Container(
                // subtle dark tint so content remains readable
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _isCameraReady && _cameraController != null
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
                                  child: _currentPosition != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (_address != null)
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  _address!,
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
                                            if (_uploadResponse != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6.0,
                                                ),
                                                child: SizedBox(
                                                  width: 180,
                                                  child: Text(
                                                    _uploadResponse!,
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
                              if (_imageFile != null)
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
                                              File(_imageFile!.path),
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
                                          File(_imageFile!.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // show send button at bottom-right when allowed
                              if (_canSendAbsen)
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
                              if (_cekModeData != null)
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
                                          'next_mod: ${_cekModeData!['next_mod'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'jenis_aturan: ${_cekModeData!['jenis_aturan'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'status: ${_cekModeData!['status'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if ((_cekModeData!['message'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              '${_cekModeData!['message']}',
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
      setState(() => _imageFile = f);
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
    final uri = Uri.parse(
      'https://absencobra.cbsguard.co.id/include/faceapi.php',
    );

    final request = http.MultipartRequest('POST', uri);
    // Read saved user info from SharedPreferences if available; fall back to
    // the temporary defaults otherwise.
    try {
      final prefs = await SharedPreferences.getInstance();
      final idPegawai =
          prefs.getString('id_pegawai') ?? prefs.getString('id_pegawai') ?? '1';
      final usernamePref =
          prefs.getString('username') ?? prefs.getString('user') ?? '1001';
      final avatarPref = prefs.getString('avatar') ?? '';
      request.fields['id_pegawai'] = idPegawai;
      request.fields['username'] = usernamePref;
      request.fields['avatar'] = avatarPref;
      log(
        'id_pegawai: $idPegawai, username: $usernamePref, avatar: $avatarPref',
      );
    } catch (e) {
      log('prefs read error: $e');
      request.fields['id_pegawai'] = '1';
      request.fields['username'] = '1001';
      request.fields['avatar'] = '';
    }

    // Attach file as 'foto' field in jpg format
    final multipartFile = await http.MultipartFile.fromPath(
      'foto',
      imageFile.path,
    );
    request.files.add(multipartFile);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengunggah foto...')));
    }

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200) {
      // Try to parse JSON response if any
      try {
        final body = resp.body;
        if (mounted) {
          setState(() => _uploadResponse = body);
          // try parse JSON and extract percent/confidence
          try {
            final parsed = json.decode(body);
            double? pct;
            if (parsed is Map) {
              final raw =
                  parsed['percent'] ??
                  parsed['persen'] ??
                  parsed['score'] ??
                  parsed['match'] ??
                  parsed['confidence'];
              if (raw != null) {
                pct = double.tryParse(raw.toString());
              } else if (parsed['data'] != null) {
                final d = parsed['data'];
                if (d is Map) {
                  final raw2 = d['percent'] ?? d['persen'] ?? d['confidence'];
                  if (raw2 != null) pct = double.tryParse(raw2.toString());
                }
              }
            }
            if (pct != null) {
              _facePercent = pct;
              _canSendAbsen = pct >= 65.0;
            }
          } catch (e) {
            log('parse upload response failed: $e');
          }
        }
        log('upload response: $body');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto berhasil diunggah')),
          );
        }

        // Refresh prefs and server profile, ensure avatar persisted before
        // navigating to Absen page.
        final saved = await _loadFromPrefsThenRefresh();
        if (saved) {
          _goToAbsenPage();
        } else {
          // If not saved yet, re-check once more; if still missing, inform user
          try {
            final prefs = await SharedPreferences.getInstance();
            final avatarNow = prefs.getString('avatar') ?? '';
            if (avatarNow.isNotEmpty) {
              _goToAbsenPage();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Avatar belum tersimpan. Mohon tunggu beberapa saat atau coba lagi.',
                    ),
                  ),
                );
              }
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Avatar belum tersimpan. Mohon tunggu beberapa saat atau coba lagi.',
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) setState(() => _uploadResponse = 'Upload finished');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Upload selesai')));
        }
      }
    } else {
      log('upload failed status: ${resp.statusCode} body: ${resp.body}');
      if (mounted) {
        setState(
          () => _uploadResponse = 'Error ${resp.statusCode}: ${resp.body}',
        );
      }
      throw Exception('Upload failed: ${resp.statusCode}');
    }
  }

  Future<bool> _loadFromPrefsThenRefresh() async {
    // Load prefs first (no spinner) so UI is responsive. Network refresh is
    // indicated via _isFetchingProfile flag.
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load most commonly used fields from prefs (if present)
      setState(() {
        nama = prefs.getString('name') ?? prefs.getString('nama') ?? '';
        email = prefs.getString('email') ?? '';
        nip = prefs.getString('nip') ?? '';
        telp = prefs.getString('telp') ?? '';
        tempatTugas = prefs.getString('tmpt_tugas') ?? '';
        jabatan = prefs.getString('jabatan') ?? '';
        site = prefs.getString('site') ?? '';
        lokasi = prefs.getString('lokasi') ?? '';
        divisi = prefs.getString('divisi') ?? '';
        // _alamatController.text = prefs.getString('alamat') ?? '';
        avatarUrl = prefs.getString('avatar') ?? '';
        // prefer local cached avatar if exists
        final localAvatar = prefs.getString('avatar_lokal');
        if (localAvatar != null && localAvatar.isNotEmpty) {
          avatarUrl = localAvatar; // will be treated as file path
        }
      });

      // Now attempt to refresh from server in background
      final token = prefs.getString('token') ?? '';
      if (token.isNotEmpty) {
        _isFetchingProfile = true;
        if (mounted) setState(() {});
        try {
          final response = await http.get(
            Uri.parse('$kBaseApiUrl/profile.php'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (response.statusCode == 200) {
            final result = json.decode(response.body);
            if (result['status'] == 'success') {
              final data = result['data'];

              // persist avatar and local cache similarly as before
              try {
                final rawAvatar = (data['avatar'] ?? '').toString();
                await prefs.setString('avatar', rawAvatar);
                final norm = _normalizeAvatarUrl(rawAvatar);
                if (norm.isNotEmpty) {
                  try {
                    final resp = await http.get(Uri.parse(norm));
                    if (resp.statusCode == 200) {
                      final bytes = resp.bodyBytes;
                      try {
                        final localPath = await saveBytesToCacheAsImage(
                          bytes,
                          filename: null,
                        );
                        await prefs.setString('avatar_lokal', localPath);
                        // prefer local avatar for immediate display
                        if (mounted) setState(() => avatarUrl = localPath);
                      } catch (e) {
                        log('save avatar local failed: $e');
                      }
                    }
                  } catch (e) {
                    log('download avatar failed: $e');
                  }
                }
              } catch (e) {
                log('failed to save avatar to prefs: $e');
              }

              // update UI fields from server response
              if (mounted) {
                setState(() {
                  nama = data['nama'] ?? nama;
                  email = data['email'] ?? email;
                  nip = data['nip'] ?? nip;
                  telp = data['telp'] ?? telp;
                  tempatTugas = data['tmpt_tugas'] ?? tempatTugas;
                  jabatan = data['jabatan'] ?? jabatan;
                  site = data['site'] ?? site;
                  lokasi = data['lokasi'] ?? lokasi;
                  divisi = data['divisi'] ?? divisi;
                  // _alamatController.text =
                  //     data['alamat'] ?? _alamatController.text;
                  _tanggalLahir = data['tgl_lahir'] != null
                      ? DateTime.tryParse(data['tgl_lahir'])
                      : _tanggalLahir;
                  _tanggalBergabung = data['tgl_joint'] != null
                      ? DateTime.tryParse(data['tgl_joint'])
                      : _tanggalBergabung;
                });
              }
            }
          }
        } catch (e) {
          log('refresh profile failed: $e');
        } finally {
          _isFetchingProfile = false;
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      log('loadFromPrefs error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    try {
      final prefs2 = await SharedPreferences.getInstance();
      final avatarNow = prefs2.getString('avatar') ?? '';
      return avatarNow.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _normalizeAvatarUrl(String raw) {
    if (raw.isEmpty) return '';
    final s = raw.trim();
    // If it's already a full URL, return as-is
    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    // If server returned a path that already contains the avatar folder, but
    // without host, normalize to full URL.
    final avatarBase = 'https://panelcobra.cbsguard.co.id/assets/img/avatar/';
    final cleaned = s.replaceFirst(RegExp(r'^/+'), '');

    // If the returned path already includes 'assets/img/avatar', just ensure
    // it's an absolute URL using the panelcobra host.
    if (cleaned.contains('assets/img/avatar')) {
      final parts = cleaned.split(RegExp(r'assets/img/avatar'));
      final filename = parts.isNotEmpty
          ? parts.last.replaceFirst(RegExp(r'^/+'), '')
          : cleaned;
      return '$avatarBase$filename';
    }

    // Otherwise assume the server returned just the filename or a relative
    // path; prepend the avatar base URL.
    return '$avatarBase$cleaned';
  }

  Future<void> _sendAbsen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idPegawai =
          prefs.getString('id_pegawai') ?? prefs.getString('id_pegawai') ?? '1';
      final username =
          prefs.getString('username') ?? prefs.getString('user') ?? '1001';
      final cabang = prefs.getString('cabang') ?? '0';
      final jenisAturan =
          (_cekModeData != null && _cekModeData!['jenis_aturan'] != null)
          ? _cekModeData!['jenis_aturan'].toString()
          : prefs.getString('jenis_aturan') ?? '';
      final idTmpt =
          prefs.getString('id_tmpt') ?? prefs.getString('idtmpt') ?? '0';
      final avatar = prefs.getString('avatar') ?? '';

      final lat = _currentPosition?.latitude.toString() ?? '';
      final lon = _currentPosition?.longitude.toString() ?? '';

      // tmpt_dikunjungi: try to inference from _cekModeData or send default list [1,2,3]
      String tmptDikunjungi = '[]';
      if (_cekModeData != null && _cekModeData!['tmpt_dikunjungi'] != null) {
        tmptDikunjungi = _cekModeData!['tmpt_dikunjungi'].toString();
      } else if (_cekModeData != null && _cekModeData!['tmpt'] != null) {
        tmptDikunjungi = json.encode(_cekModeData!['tmpt']);
      }
      // if still empty or equals '[]', set default [1,2,3]
      if (tmptDikunjungi.trim().isEmpty || tmptDikunjungi.trim() == '[]') {
        tmptDikunjungi = json.encode([1, 2, 3]);
      }

      log(
        "Preparing multipart absen masuk: id_pegawai=$idPegawai username=$username cabang=$cabang lat=$lat lon=$lon jenis_aturan=$jenisAturan id_tmpt=$idTmpt avatar=$avatar tmpt_dikunjungi=$tmptDikunjungi",
      );

      // Ensure photo exists
      if (_imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Foto belum diambil')));
        }
        return;
      }

      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/include/absenapi.php',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add expected form fields
      request.fields['id_pegawai'] = idPegawai;
      request.fields['username'] = username;
      request.fields['cabang'] = cabang;
      request.fields['latitude'] = lat;
      request.fields['longitude'] = lon;
      request.fields['jenis_aturan'] = jenisAturan;
      request.fields['id_tmpt'] = idTmpt;
      request.fields['avatar'] = avatar;
      request.fields['tmpt_dikunjungi'] = tmptDikunjungi;

      // Attach photo file as 'foto'
      final mp = await http.MultipartFile.fromPath('foto', _imageFile!.path);
      request.files.add(mp);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengirim absen...')));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        try {
          final parsed = json.decode(resp.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  parsed['message']?.toString() ?? 'Absen berhasil',
                ),
              ),
            );
          }
          log('absen masuk response: ${resp.body}');
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Absen berhasil')));
          }
          log('absen masuk non-json response: ${resp.body}');
        }
      } else {
        log('absen send failed ${resp.statusCode} ${resp.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal kirim absen: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      log('sendAbsen error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error mengirim absen: $e')));
      }
    }
  }
}
