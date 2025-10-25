import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:absencobra/pages/dashboard_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../user.dart';

class AbsenMasukPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  const AbsenMasukPage({super.key, this.data});

  @override
  State<AbsenMasukPage> createState() => _AbsenMasukPageState();
}

class _AbsenMasukPageState extends State<AbsenMasukPage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  XFile? _imageFile;
  Position? _currentPosition;
  String? _address;
  String? _uploadResponse;
  bool _canSendAbsen = false;
  Map<String, dynamic>? _cekModeData;
  double? _facePercent;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

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
      // camera initialized; manual capture will be used (tap shutter)
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
            'Absen Masuk',
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
                                                  color: Colors.white70,
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
                                                      fontSize: 11,
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
                              // face percentage box at top-right
                              if (_facePercent != null)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_facePercent!.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.yellow,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
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
                                          color: Colors.white70,
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
                                            fontSize: 10,
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
      // If we already have an image, resume camera first to take a new picture
      if (_imageFile != null) {
        await _cameraController!.resumePreview();
      }

      final f = await _cameraController!.takePicture();

      // Pause camera preview after taking picture
      await _cameraController!.pausePreview();

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
    // Read saved user info from User object in SharedPreferences
    try {
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

      if (user != null) {
        request.fields['id_pegawai'] = user.id_pegawai.toString();
        request.fields['username'] = user.username;
        request.fields['avatar'] = user.avatar;
        log(
          'id_pegawai: ${user.id_pegawai}, username: ${user.username}, avatar: ${user.avatar}',
        );
      } else {
        // Fallback to defaults if user data not available
        request.fields['id_pegawai'] = '1';
        request.fields['username'] = '1001';
        request.fields['avatar'] = '';
        log('User data not available, using fallback values');
      }
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
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text('Foto berhasil diunggah')),
        //   );
        // }
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

  Future<void> _sendAbsen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data from SharedPreferences
      final userJson = prefs.getString('user');
      User? user;
      if (userJson != null) {
        try {
          user = User.fromJson(json.decode(userJson));
        } catch (e) {
          log('Error parsing user data in _sendAbsen: $e');
        }
      }

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data user tidak tersedia')),
          );
        }
        return;
      }

      final idPegawai = user.id_pegawai.toString();
      final username = user.username;
      final cabang = user.id_cabang.toString();
      final jenisAturan =
          (_cekModeData != null && _cekModeData!['jenis_aturan'] != null)
          ? _cekModeData!['jenis_aturan'].toString()
          : user.jenis_aturan;
      final idTmpt = user.id_tmpt.toString();
      final avatar = user.avatar;

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
        "Preparing multipart absen masuk: id_pegawai=$idPegawai username=$username cabang=$cabang latitude=$lat longitude=$lon jenis_aturan=$jenisAturan id_tmpt=$idTmpt avatar=$avatar tmpt_dikunjungi=$tmptDikunjungi",
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
          _goToDashboard();
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
