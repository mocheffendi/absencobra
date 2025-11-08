import 'dart:developer';
import 'dart:io';
import 'package:cobra_apps/pages/patrol_photo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
// removed unused ScannerOverlay import; using QrisScannerAnimation from scanner_overlay2.dart
import 'package:cobra_apps/widgets/scanner_overlay2.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../providers/patrol_provider.dart';

// Local provider to indicate camera initialization for this page
class PatrolCameraInitNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setInitialized(bool v) => state = v;
}

final patrolCameraInitProvider =
    NotifierProvider<PatrolCameraInitNotifier, bool>(
      () => PatrolCameraInitNotifier(),
    );

class PatrolPage extends ConsumerStatefulWidget {
  const PatrolPage({super.key});

  @override
  ConsumerState<PatrolPage> createState() => _PatrolPageState();
}

class _PatrolPageState extends ConsumerState<PatrolPage> {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();

    // Get current location when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeCamera();
      ref.read(patrolProvider.notifier).getCurrentLocation();
    });
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
        // mark camera initialized via local provider so UI can react without local setState
        ref.read(patrolCameraInitProvider.notifier).setInitialized(true);
        _startBarcodeScanning();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startBarcodeScanning() {
    log('PatrolPage: Starting barcode scanning');
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Take picture periodically for barcode scanning
    Future.doWhile(() async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          ref.read(processingScanProvider)) {
        return false;
      }

      try {
        final XFile file = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(file.path);
        final barcodes = await _barcodeScanner!.processImage(inputImage);

        log('PatrolPage: Detected ${barcodes.length} barcodes');

        for (final barcode in barcodes) {
          final code = barcode.rawValue;
          if (code != null && !ref.read(processingScanProvider)) {
            log('PatrolPage: Processing barcode: $code');
            ref.read(patrolProvider.notifier).setProcessingScan(true);

            if (!mounted) {
              await File(file.path).delete();
              return false;
            }

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PatrolPhotoPage(qrId: code)),
            );

            if (result == true) {
              if (!mounted) {
                await File(file.path).delete();
                return false;
              }
              Navigator.pop(
                context,
                true,
              ); // kembali ke Dashboard, trigger refresh
              await File(file.path).delete();
              return false; // Stop scanning
            } else {
              ref.read(patrolProvider.notifier).setProcessingScan(false);
            }
            break; // Process only the first barcode found
          }
        }

        // Delete the temporary file
        await File(file.path).delete();

        // Wait a bit before taking next picture
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Error processing barcode: $e');
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      return true; // Continue the loop
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_cameraController != null) {
      _cameraController!.pausePreview();
      _cameraController!.resumePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patrolState = ref.watch(patrolProvider);
    final isLoading = patrolState.isLoading;
    final currentAddress = patrolState.currentAddress;
    final currentPosition = patrolState.currentPosition;

    // Listen to error changes
    ref.listen<String?>(patrolErrorProvider, (previous, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        // Clear error after showing
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(patrolProvider.notifier).clearError();
        });
      }
    });

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
          "Patroli Scan QRCode",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Camera preview
                Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          _cameraController != null &&
                                  _cameraController!.value.isInitialized
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          // Scanner overlay on top of camera preview
                          const Positioned.fill(child: QrisScannerAnimation()),
                        ],
                      ),
                    ),
                  ],
                ),

                // Top-left overlay for address and coordinates
                Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentAddress != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Text(
                              "Lokasi: $currentAddress",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      if (currentPosition != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Lat: ${currentPosition.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.longitude.toStringAsFixed(6)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom center camera-style Scan Ulang button
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(patrolProvider.notifier)
                                .setProcessingScan(false);
                            ref
                                .read(patrolProvider.notifier)
                                .setScanning(false);
                            ref
                                .read(patrolProvider.notifier)
                                .getCurrentLocation();
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner?.close();
    super.dispose();
  }
}
