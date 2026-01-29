// import 'dart:io';

import 'package:cobra_apps/models/user.dart';
import 'package:cobra_apps/pages/dashboard_page.dart';
import 'package:cobra_apps/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detector_view.dart';
import 'package:cobra_apps/widgets/barcode_detector_painter.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cobra_apps/pages/absen_pulang_page.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/providers/page_providers.dart';
import 'package:cobra_apps/widgets/scanner_overlay2.dart';

class ScanPulangPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const ScanPulangPage({super.key, this.data});

  @override
  ConsumerState<ScanPulangPage> createState() => _ScanPulangPageState();
}

class _ScanPulangPageState extends ConsumerState<ScanPulangPage> {
  BarcodeScanner? _barcodeScanner;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  bool _isBusy = false;

  @override
  void reassemble() {
    super.reassemble();
    // no-op for DetectorView
  }

  @override
  void dispose() {
    // Stop scanning and clear transient scan state when disposing the page
    try {
      ref.read(scanPulangProvider.notifier).clear();
    } catch (e) {
      log('Error clearing scanPulangProvider state in dispose: $e');
    }
    _barcodeScanner?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Don't mutate providers while the widget tree is building.
    // Move provider writes to a post-frame callback below.
    _barcodeScanner = BarcodeScanner();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Clear transient scan state and schedule enabling scanning
      try {
        final notifier = ref.read(scanPulangProvider.notifier);
        notifier.setLastCode(null);
        notifier.setQrValidationResult(null);
        notifier.setIsScanning(false);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            notifier.setIsScanning(true);
            log(
              'scan_pulang_page: isScanning set to true by delayed postFrame',
            );
          } catch (e) {
            log('Error enabling isScanning after delay: $e');
          }
        });
        notifier.setIsValidating(false);
        notifier.setNavigated(false);
        notifier.setQrLocation(null);
        notifier.setDistanceMeters(null);
        notifier.setIsScanning(false);
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            notifier.setIsScanning(true);
          } catch (e) {
            log('Error enabling isScanning after delay: $e');
          }
        });
      } catch (e) {
        log('Error clearing scanPulangProvider state in postFrame: $e');
      }
      await _ensureAndGetLocation();
    });
  }

  // DetectorView will supply frames; handle them in _processImage.

  Future<void> _validateQRCode(String code) async {
    try {
      log("coba validasi qr");
      final prefs = await SharedPreferences.getInstance();
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
      final jenis = 'pulang'; // or 'pulang' for absen pulang

      // final user = ref.watch(userPrefsProvider);
      // final idPegawai = user?['idPegawai']?.toString();
      // Build explicit Map<String,String> and send raw JSON bodyString
      final requestMap = <String, String>{
        'qr': code.toString(),
        'id_pegawai': idPegawai.toString(),
        'jenis': jenis.toString(),
      };
      final bodyString = jsonEncode(requestMap);
      log('Validating QR with bodyString: $bodyString');
      final url = Uri.parse('$kBaseUrl/include/validasi_qr.php');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: bodyString,
      );

      if (resp.statusCode == 200) {
        Map<String, dynamic>? data;
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
          log('QR validation parse error: $e body="${resp.body}"');
          data = {'success': false, 'message': 'Invalid server response'};
        }

        // update provider state instead of local setState
        ref.read(scanPulangProvider.notifier).setQrValidationResult(data);
        ref.read(scanPulangProvider.notifier).setIsValidating(false);
        if (data['success'] != true) {
          ref
              .read(scanPulangProvider.notifier)
              .setValidationError(
                data['message']?.toString() ?? 'Invalid server response',
              );
        } else {
          ref.read(scanPulangProvider.notifier).setValidationError(null);
        }

        // --- AUTO NAVIGATE LOGIC ---
        final providerState = ref.read(scanPulangProvider);
        if (!providerState.navigated && data['success'] == true) {
          double? maxDistance;
          if (data['max'] != null) {
            maxDistance = double.tryParse(data['max'].toString());
          }

          double? distance;
          final latStr = data['latitude']?.toString();
          final lonStr = data['longitude']?.toString();
          final lat = latStr != null ? double.tryParse(latStr) : null;
          final lon = lonStr != null ? double.tryParse(lonStr) : null;
          if (lat != null &&
              lon != null &&
              providerState.currentPosition != null) {
            distance = Geolocator.distanceBetween(
              lat,
              lon,
              providerState.currentPosition!.latitude,
              providerState.currentPosition!.longitude,
            );
          } else {
            distance = providerState.distanceMeters;
          }

          if (maxDistance != null &&
              distance != null &&
              distance <= maxDistance) {
            // Stop scanning before navigating so old scan doesn't race back in
            ref.read(scanPulangProvider.notifier).setIsScanning(false);
            ref.read(scanPulangProvider.notifier).setNavigated(true);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AbsenPulangPage(data: data)),
            );
          }
        }
        // --- END AUTO NAVIGATE LOGIC ---
      } else {
        ref
            .read(scanPulangProvider.notifier)
            .setValidationError('Status ${resp.statusCode}: ${resp.body}');
        ref.read(scanPulangProvider.notifier).setIsValidating(false);
      }
    } catch (e) {
      ref.read(scanPulangProvider.notifier).setValidationError('Error: $e');
      ref.read(scanPulangProvider.notifier).setIsValidating(false);
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
        ref.read(scanPulangProvider.notifier).setAddress(addr);
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
          .read(scanPulangProvider.notifier)
          .setCurrentPosition(PositionData(pos.latitude, pos.longitude));
      _resolveAddress(pos);
    } catch (e) {
      log('Error obtaining location: $e');
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    final isScanning = ref.read(scanPulangProvider).isScanning;
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
      final state = ref.read(scanPulangProvider);
      final last = state.lastCode;
      final lastTs = state.lastCodeTimestamp ?? 0;
      if (code == last && (now - lastTs) < 2000) {
        continue;
      }

      ref.read(scanPulangProvider.notifier).setLastCodeWithTimestamp(code);
      ref.read(scanPulangProvider.notifier).setIsValidating(true);
      ref.read(scanPulangProvider.notifier).setQrValidationResult(null);
      ref.read(scanPulangProvider.notifier).setValidationError(null);

      await _validateQRCode(code);
      break;
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanPulangProvider);

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
          title: const Text('Scan Pulang'),
          elevation: 0,
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
          // centerTitle: true,
          // Keep the AppBar minimal and move the camera/overlay UI into Scaffold.body
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DetectorView(
                      title: 'Scan Pulang',
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
                      child: state.currentPosition != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${state.currentPosition!.latitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Lon: ${state.currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                if (state.address != null)
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      state.address!,
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                      color: Colors.white,
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

                  // Bottom-left overlays: rescan, qr data, validation results
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
                                  scanPulangProvider.notifier,
                                );
                                notifier.setLastCode(null);
                                notifier.setQrValidationResult(null);
                                notifier.setValidationError(null);
                                notifier.setIsValidating(false);
                                notifier.setIsScanning(true);
                                log('User requested rescan (Scan Pulang)');
                              } catch (e) {
                                log('Error during rescan (Scan Pulang): $e');
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

                        if (state.lastCode != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'QR Data: ${state.lastCode}',
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                ),
                              ),
                              if (state.qrLocation != null)
                                Text(
                                  'QR Lokasi: lat=${state.qrLocation!['lat']}, lon=${state.qrLocation!['lon']}',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              if (state.distanceMeters != null)
                                Text(
                                  'Jarak ke QR: ${_formatDistance(state.distanceMeters!)}',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (state.isValidating)
                                const Text(
                                  'Validasi QR...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              if (state.validationError != null)
                                Text(
                                  state.validationError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),

                        // validasi_qr result overlay kiri bawah
                        if (state.qrValidationResult != null)
                          Builder(
                            builder: (context) {
                              double? distance;
                              final latStr = state
                                  .qrValidationResult!['latitude']
                                  ?.toString();
                              final lonStr = state
                                  .qrValidationResult!['longitude']
                                  ?.toString();
                              final lat = latStr != null
                                  ? double.tryParse(latStr)
                                  : null;
                              final lon = lonStr != null
                                  ? double.tryParse(lonStr)
                                  : null;
                              if (lat != null &&
                                  lon != null &&
                                  state.currentPosition != null) {
                                distance = Geolocator.distanceBetween(
                                  lat,
                                  lon,
                                  state.currentPosition!.latitude,
                                  state.currentPosition!.longitude,
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
                                    ...state.qrValidationResult!.entries.map(
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
                                          'Jarak ke lokasi validasi: ${_formatDistance(distance)}',
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
    // Ensure camera and barcode scanner are disposed and clear transient scan state
    try {
      ref.read(scanPulangProvider.notifier).clear();
    } catch (e) {
      log('Error clearing scanPulangProvider state in _goToDashboard: $e');
    }
    // No camera controller to stop when using DetectorView
    if (!mounted) return;
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
