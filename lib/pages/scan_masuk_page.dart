// import 'dart:io';

import 'package:cobra_apps/models/user.dart';
import 'package:cobra_apps/utility/settings.dart';
import 'package:cobra_apps/widgets/scanner_overlay2.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detector_view.dart';
import 'package:cobra_apps/widgets/barcode_detector_painter.dart';
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
// removed unused import 'scanner_overlay2' (unused)

class ScanMasukPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const ScanMasukPage({super.key, this.data});

  @override
  ConsumerState<ScanMasukPage> createState() => _ScanMasukPageState();
}

class _ScanMasukPageState extends ConsumerState<ScanMasukPage> {
  BarcodeScanner? _barcodeScanner;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  bool _isBusy = false;

  @override
  void reassemble() {
    super.reassemble();
    // nothing needed for DetectorView reassemble
  }

  @override
  void dispose() {
    ref.read(scanMasukProvider.notifier).clear();

    // Stop scanning and clear transient scan state when disposing the page
    try {
      ref.read(scanMasukProvider.notifier).setIsScanning(false);
    } catch (_) {}
    try {
      ref.read(scanMasukProvider.notifier).setLastCode(null);
      ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
      ref.read(scanMasukProvider.notifier).setValidationError(null);
      ref.read(scanMasukProvider.notifier).setIsValidating(false);
      ref.read(scanMasukProvider.notifier).setNavigated(false);
      ref.read(scanMasukProvider.notifier).setQrLocation(null);
      ref.read(scanMasukProvider.notifier).setDistanceMeters(null);
    } catch (e) {
      log('Error clearing scanMasukProvider state in dispose: $e');
    }

    _barcodeScanner?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Move provider mutations here so we don't modify providers while
      // the widget tree is building.
      try {
        ref.read(scanMasukProvider.notifier).setLastCode(null);
        ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
        ref.read(scanMasukProvider.notifier).setValidationError(null);
        ref.read(scanMasukProvider.notifier).setIsValidating(false);
        ref.read(scanMasukProvider.notifier).setNavigated(false);
        ref.read(scanMasukProvider.notifier).setQrLocation(null);
        ref.read(scanMasukProvider.notifier).setDistanceMeters(null);
        // start disabled then enable after a short delay to avoid immediate
        // re-detection of the same QR when returning from Absen page
        ref.read(scanMasukProvider.notifier).setIsScanning(false);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            ref.read(scanMasukProvider.notifier).setIsScanning(true);
            log('scan_masuk_page: isScanning set to true by delayed postFrame');
          } catch (e) {
            log('Error enabling isScanning after delay: $e');
          }
        });
      } catch (e) {
        log('Error clearing scanMasukProvider state in initState: $e');
      }

      await _ensureAndGetLocation();
    });
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
      log('Error obtaining location: $e');
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    final isScanning = ref.read(scanMasukProvider).isScanning;
    if (!isScanning) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() => _text = '');

    final barcodes = await _barcodeScanner!.processImage(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = BarcodeDetectorPainter(
        barcodes,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Barcodes found: ${barcodes.length}\n\n';
      for (final barcode in barcodes) {
        text += 'Barcode: ${barcode.rawValue}\n\n';
      }
      _text = text;
      _customPaint = null;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final barcode in barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;
      final state = ref.read(scanMasukProvider);
      final last = state.lastCode;
      final lastTs = state.lastCodeTimestamp ?? 0;
      if (code == last && (now - lastTs) < 2000) {
        continue;
      }

      ref.read(scanMasukProvider.notifier).setLastCodeWithTimestamp(code);
      ref.read(scanMasukProvider.notifier).setIsValidating(true);
      ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
      ref.read(scanMasukProvider.notifier).setValidationError(null);

      await _validateQRCode(code);
      break;
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  // DetectorView will provide camera frames; use _processImage to handle them.

  Future<void> _validateQRCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // final idPegawai = prefs.getString('idpegawai') ?? '1';
      String idPegawai = '1';
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final user = User.fromJson(json.decode(userJson));
          idPegawai = user.id_pegawai.toString();
        } catch (e) {
          idPegawai = prefs.getString('id_pegawai') ?? '1';
        }
      } else {
        idPegawai = prefs.getString('id_pegawai') ?? '1';
      }

      final jenis = 'masuk'; // or 'pulang' for absen pulang
      final url = Uri.parse('$kBaseUrl/include/validasi_qr.php');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr': code, 'id_pegawai': idPegawai, 'jenis': jenis}),
      );
      log('Validating QR code: $code for id_pegawai: $idPegawai jenis: $jenis');
      if (resp.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          final body = resp.body.trim();
          if (body.isEmpty) throw FormatException('Empty response');
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) {
            data = parsed;
          } else if (parsed is List &&
              parsed.isNotEmpty &&
              parsed.first is Map) {
            data = Map<String, dynamic>.from(parsed.first as Map);
          } else {
            data = {'success': false, 'message': 'Invalid response format'};
          }
        } catch (e) {
          log('QR validation parse error: $e -- raw:${resp.body}');
          data = {'success': false, 'message': 'Invalid server response'};
        }

        ref.read(scanMasukProvider.notifier).setQrValidationResult(data);
        ref.read(scanMasukProvider.notifier).setIsValidating(false);

        // --- AUTO NAVIGATE LOGIC ---
        if (!ref.read(scanMasukProvider).navigated && data['success'] == true) {
          double? maxDistance;
          if (data['max'] != null) {
            maxDistance = double.tryParse(data['max'].toString());
          }
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
            ref.read(scanMasukProvider.notifier).setIsScanning(false);
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
      log('Error validating QR code: $e');
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
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Scan Masuk'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async => await _goToDashboard(),
          ),
          actions: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () async {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Flash not available in this mode'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.flash_on, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DetectorView(
                      title: 'Scan Masuk',
                      customPaint: _customPaint,
                      text: _text,
                      onImage: _processImage,
                      initialCameraLensDirection: _cameraLensDirection,
                      onCameraLensDirectionChanged: (value) =>
                          _cameraLensDirection = value,
                    ),
                  ),

                  // Scanner overlay sits above the camera preview but below UI overlays
                  Positioned.fill(child: const QrisScannerAnimation()),

                  // location overlay top-left + QR data + distance
                  Positioned(
                    left: 12,
                    top: 100,
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
                        // Rescan button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              try {
                                final notifier = ref.read(
                                  scanMasukProvider.notifier,
                                );
                                notifier.setLastCode(null);
                                notifier.setQrValidationResult(null);
                                notifier.setValidationError(null);
                                notifier.setIsValidating(false);
                                notifier.setIsScanning(true);
                                log('User requested rescan (Scan Masuk)');
                              } catch (e) {
                                log('Error during rescan (Scan Masuk): $e');
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Scan Ulang'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
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
                                  'Jarak ke QR: ${_formatDistance(ref.watch(scanMasukProvider).distanceMeters!)}',
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
                  // Positioned(
                  //   top: 12,
                  //   right: 12,
                  //   child: Material(
                  //     color: Colors.transparent,
                  //     child: InkWell(
                  //       borderRadius: BorderRadius.circular(24),
                  //       onTap: () async {
                  //         if (_cameraController != null) {
                  //           try {
                  //             await _cameraController!.setFlashMode(
                  //               _cameraController!.value.flashMode ==
                  //                       FlashMode.off
                  //                   ? FlashMode.torch
                  //                   : FlashMode.off,
                  //             );
                  //             if (!context.mounted) return;
                  //             ScaffoldMessenger.of(context).showSnackBar(
                  //               const SnackBar(content: Text('Flash toggled')),
                  //             );
                  //           } catch (e) {
                  //             log('Error toggling flash: $e');
                  //           }
                  //         }
                  //       },
                  //       child: Ink(
                  //         decoration: BoxDecoration(
                  //           color: Colors.black54,
                  //           shape: BoxShape.circle,
                  //         ),
                  //         child: const Padding(
                  //           padding: EdgeInsets.all(10),
                  //           child: Icon(
                  //             Icons.flash_on,
                  //             color: Colors.yellow,
                  //             size: 28,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
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

  Future<void> _goToDashboard() async {
    // No camera controller to stop when using DetectorView
    if (!mounted) return;
    // Clear QR validation-related transient state when leaving the page
    try {
      // stop scanning immediately
      ref.read(scanMasukProvider.notifier).setIsScanning(false);
      ref.read(scanMasukProvider.notifier).setLastCode(null);
      ref.read(scanMasukProvider.notifier).setQrValidationResult(null);
      ref.read(scanMasukProvider.notifier).setValidationError(null);
      ref.read(scanMasukProvider.notifier).setIsValidating(false);
      ref.read(scanMasukProvider.notifier).setNavigated(false);
      ref.read(scanMasukProvider.notifier).setQrLocation(null);
      ref.read(scanMasukProvider.notifier).setDistanceMeters(null);
    } catch (e) {
      log('Error clearing scanMasukProvider state on back: $e');
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(1)} meter';
  }
}
