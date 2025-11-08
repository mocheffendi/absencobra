import 'dart:io';

import 'package:cobra_apps/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/pages/absen_masuk_page.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/providers/page_providers.dart';
import 'package:cobra_apps/widgets/scanner_overlay2.dart';

class ScanMasukPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const ScanMasukPage({super.key, this.data});

  @override
  ConsumerState<ScanMasukPage> createState() => _ScanMasukPageState();
}

class _ScanMasukPageState extends ConsumerState<ScanMasukPage> {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _cameraController?.pausePreview();
      _cameraController?.resumePreview();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeCamera();
      await _ensureAndGetLocation();
    });
  }

  Future<void> _ensureAndGetLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      ref
          .read(scanMasukProvider.notifier)
          .setCurrentPosition(PositionData(pos.latitude, pos.longitude));
      _resolveAddress(pos);
    } catch (e) {
      // ignore
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
        if (pm.administrativeArea != null &&
            pm.administrativeArea!.isNotEmpty) {
          parts.add(pm.administrativeArea!);
        }
        if (pm.country != null && pm.country!.isNotEmpty) {
          parts.add(pm.country!);
        }
        final addr = parts.join(', ');
        if (!mounted) return;
        ref.read(scanMasukProvider.notifier).setAddress(addr);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use the first available camera (usually back camera)
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        // mark camera initialized in provider (so UI can react)
        ref.read(scanMasukProvider.notifier).setCameraInitialized(true);
        _startBarcodeScanning();
      }
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  void _startBarcodeScanning() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Take picture periodically for barcode scanning
    Future.doWhile(() async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return false;
      }

      try {
        final XFile file = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(file.path);
        final barcodes = await _barcodeScanner!.processImage(inputImage);

        for (final barcode in barcodes) {
          final code = barcode.rawValue;
          if (code != null && code != ref.read(scanMasukProvider).lastCode) {
            ref.read(scanMasukProvider.notifier).setLastCode(code);
            log('Scanned QR Code: $code');
            ref.read(scanMasukProvider.notifier).setIsValidating(true);
            ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
            ref.read(scanMasukProvider.notifier).setValidationError(null);

            await _validateQRCode(code);
            break; // Process only the first barcode found
          }
        }

        // Delete the temporary file
        await File(file.path).delete();

        // Wait a bit before taking next picture
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        log('Error processing barcode: $e');
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      return true; // Continue the loop
    });
  }

  Future<void> _validateQRCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idPegawai = prefs.getString('idpegawai') ?? '1';
      final jenis = 'masuk'; // or 'pulang' for absen pulang
      final url = Uri.parse('$kBaseUrl/include/validasi_qr.php');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr': code, 'id_pegawai': idPegawai, 'jenis': jenis}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        ref.read(scanMasukProvider.notifier).setQrValidationResult(data);
        ref.read(scanMasukProvider.notifier).setIsValidating(false);
        // --- AUTO NAVIGATE LOGIC ---
        // Only navigate if not already navigated
        if (!ref.read(scanMasukProvider).navigated && data['success'] == true) {
          // Use distance from validation result if available, else from _distanceMeters
          double? maxDistance;
          if (data['max'] != null) {
            maxDistance = double.tryParse(data['max'].toString());
          }
          // Calculate distance to validation location
          double? distance;
          final latStr = data['latitude']?.toString();
          final lonStr = data['longitude']?.toString();
          final lat = latStr != null ? double.tryParse(latStr) : null;
          final lon = lonStr != null ? double.tryParse(lonStr) : null;
          final currPos = ref.read(scanMasukProvider).currentPosition;
          if (lat != null && lon != null && currPos != null) {
            distance = Geolocator.distanceBetween(
              lat,
              lon,
              currPos.latitude,
              currPos.longitude,
            );
          } else {
            distance = ref.read(scanMasukProvider).distanceMeters;
          }
          if (maxDistance != null &&
              distance != null &&
              distance <= maxDistance) {
            ref.read(scanMasukProvider.notifier).setNavigated(true);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AbsenMasukPage(data: data)),
            );
          }
        }
        // --- END AUTO NAVIGATE LOGIC ---
      } else {
        ref
            .read(scanMasukProvider.notifier)
            .setValidationError('Status ${resp.statusCode}: ${resp.body}');
        ref.read(scanMasukProvider.notifier).setIsValidating(false);
      }
    } catch (e) {
      ref.read(scanMasukProvider.notifier).setValidationError('Error: $e');
      ref.read(scanMasukProvider.notifier).setIsValidating(false);
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
        appBar: AppBar(
          title: const Text('Scan Masuk'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async => await _goToDashboard(),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Positioned.fill(child: CameraPreview(_cameraController!))
                  else
                    const Center(child: CircularProgressIndicator()),

                  // Scanner overlay sits above the camera preview but below UI overlays
                  Positioned.fill(child: const QrisScannerAnimation()),
                  // QR Scanner overlay
                  // Positioned.fill(
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       border: Border.all(color: Colors.white, width: 2),
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     margin: const EdgeInsets.all(40),
                  //     child: const Center(
                  //       child: Text(
                  //         'Position QR Code here',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // location overlay top-left + QR data + distance
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
                          ref.watch(scanMasukProvider).currentPosition != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${ref.watch(scanMasukProvider).currentPosition!.latitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Lon: ${ref.watch(scanMasukProvider).currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                if (ref.watch(scanMasukProvider).address !=
                                    null)
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      ref.watch(scanMasukProvider).address!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                                const SizedBox(height: 8),
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
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Column(
                      children: [
                        if (ref.watch(scanMasukProvider).lastCode != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'QR Data: ${ref.watch(scanMasukProvider).lastCode}',
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                ),
                              ),
                              if (ref.watch(scanMasukProvider).qrLocation !=
                                  null)
                                Text(
                                  'QR Lokasi: lat=${ref.watch(scanMasukProvider).qrLocation!['lat']}, lon=${ref.watch(scanMasukProvider).qrLocation!['lon']}',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              if (ref.watch(scanMasukProvider).distanceMeters !=
                                  null)
                                Text(
                                  'Jarak ke QR: ${ref.watch(scanMasukProvider).distanceMeters!.toStringAsFixed(1)} meter',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (ref.watch(scanMasukProvider).isValidating)
                                const Text(
                                  'Validasi QR...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              if (ref
                                      .watch(scanMasukProvider)
                                      .validationError !=
                                  null)
                                Text(
                                  ref.watch(scanMasukProvider).validationError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        // validasi_qr result overlay kiri bawah
                        if (ref.watch(scanMasukProvider).qrValidationResult !=
                            null)
                          Builder(
                            builder: (context) {
                              double? distance;
                              final latStr = ref
                                  .watch(scanMasukProvider)
                                  .qrValidationResult!['latitude']
                                  ?.toString();
                              final lonStr = ref
                                  .watch(scanMasukProvider)
                                  .qrValidationResult!['longitude']
                                  ?.toString();
                              final lat = latStr != null
                                  ? double.tryParse(latStr)
                                  : null;
                              final lon = lonStr != null
                                  ? double.tryParse(lonStr)
                                  : null;
                              final currPos = ref
                                  .watch(scanMasukProvider)
                                  .currentPosition;
                              if (lat != null &&
                                  lon != null &&
                                  currPos != null) {
                                distance = Geolocator.distanceBetween(
                                  lat,
                                  lon,
                                  currPos.latitude,
                                  currPos.longitude,
                                );
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hasil Validasi QR:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    ...ref
                                        .watch(scanMasukProvider)
                                        .qrValidationResult!
                                        .entries
                                        .map(
                                          (e) => Text(
                                            '${e.key}: ${e.value}',
                                            style: TextStyle(
                                              color: e.key == 'success'
                                                  ? (e.value == true
                                                        ? Colors.greenAccent
                                                        : Colors.redAccent)
                                                  : Colors.white,
                                              fontWeight: e.key == 'success'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    if (distance != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Jarak ke lokasi validasi: ${distance.toStringAsFixed(1)} meter',
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Flash button overlay top right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          if (_cameraController != null) {
                            try {
                              await _cameraController!.setFlashMode(
                                _cameraController!.value.flashMode ==
                                        FlashMode.off
                                    ? FlashMode.torch
                                    : FlashMode.off,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Flash toggled')),
                              );
                            } catch (e) {
                              log('Error toggling flash: $e');
                            }
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.yellow,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToDashboard() async {
    try {
      // stop camera first
      await _cameraController?.stopImageStream();
      await _cameraController?.pausePreview();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }
}
