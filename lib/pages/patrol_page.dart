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
import 'package:cobra_apps/providers/camera_provider.dart';

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
  BarcodeScanner? _barcodeScanner;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();

    // Get current location when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize central camera provider
      await ref.read(cameraProvider.notifier).initializeCamera();
      // notify local page provider if needed
      if (ref.read(cameraProvider) != null &&
          ref.read(cameraProvider)!.value.isInitialized) {
        ref.read(patrolCameraInitProvider.notifier).setInitialized(true);
      }
      // start scanning when camera is ready
      await _startWhenReady();
      ref.read(patrolProvider.notifier).getCurrentLocation();
    });
  }

  Future<void> _startWhenReady() async {
    // Wait until provider's controller is available then start scanning
    if (ref.read(cameraProvider) != null &&
        ref.read(cameraProvider)!.value.isInitialized) {
      _startBarcodeScanning();
      return;
    }
    // Poll briefly until ready (small delay loop)
    for (var i = 0; i < 10; i++) {
      final c = ref.read(cameraProvider);
      if (c != null && c.value.isInitialized) {
        _startBarcodeScanning();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _startBarcodeScanning() {
    log('PatrolPage: Starting barcode scanning');
    final controller = ref.read(cameraProvider);
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    // Take picture periodically for barcode scanning
    Future.doWhile(() async {
      if (!mounted ||
          ref.read(cameraProvider) == null ||
          !ref.read(cameraProvider)!.value.isInitialized ||
          ref.read(processingScanProvider)) {
        return false;
      }

      try {
        final XFile? file = await ref
            .read(cameraProvider.notifier)
            .takePicture();
        if (file == null) {
          await Future.delayed(const Duration(milliseconds: 300));
          return true;
        }
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
    // Use central camera provider to pause/resume preview (fire-and-forget)
    ref.read(cameraProvider.notifier).pausePreview();
    ref.read(cameraProvider.notifier).resumePreview();
  }

  @override
  Widget build(BuildContext context) {
    final patrolState = ref.watch(patrolProvider);
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
        // centerTitle: true,
        title: const Text(
          "Patroli Scan QRCode",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child:
                (ref.watch(cameraProvider) != null &&
                    ref.watch(cameraProvider)!.value.isInitialized)
                ? CameraPreview(ref.watch(cameraProvider)!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Positioned.fill(child: QrisScannerAnimation()),

          // Top-left overlay for address and coordinates
          // Positioned(
          //   top: 100,
          //   left: 12,
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       if (currentAddress != null)
          //         Container(
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 10,
          //             vertical: 6,
          //           ),
          //           decoration: BoxDecoration(
          //             color: Color.fromRGBO(255, 255, 255, 0.85),
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //           child: ConstrainedBox(
          //             constraints: BoxConstraints(
          //               maxWidth: MediaQuery.of(context).size.width * 0.6,
          //             ),
          //             child: Text(
          //               "Lokasi: $currentAddress",
          //               style: const TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 color: Colors.black87,
          //                 fontSize: 13,
          //               ),
          //             ),
          //           ),
          //         ),
          //       if (currentPosition != null)
          //         Container(
          //           margin: const EdgeInsets.only(top: 6),
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 10,
          //             vertical: 6,
          //           ),
          //           decoration: BoxDecoration(
          //             color: Color.fromRGBO(255, 255, 255, 0.85),
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //           child: Text(
          //             "Lat: ${currentPosition.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.longitude.toStringAsFixed(6)}",
          //             style: const TextStyle(
          //               fontWeight: FontWeight.bold,
          //               color: Colors.black54,
          //               fontSize: 13,
          //             ),
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
          Positioned(
            left: 12,
            top: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: (currentAddress != null && currentPosition != null)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lat: ${currentPosition.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Long: ${currentPosition.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            "Lokasi: $currentAddress",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  : const Text(
                      'Mencari lokasi...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
            ),
          ),
          // Bottom center camera-style Scan Ulang button
          // Positioned(
          //   bottom: 24,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: ClipOval(
          //       child: Material(
          //         color: Color.fromRGBO(255, 255, 255, 0.12),
          //         child: InkWell(
          //           onTap: () {
          //             ref
          //                 .read(patrolProvider.notifier)
          //                 .setProcessingScan(false);
          //             ref.read(patrolProvider.notifier).setScanning(false);
          //             ref.read(patrolProvider.notifier).getCurrentLocation();
          //           },
          //           child: Container(
          //             width: 64,
          //             height: 64,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //               border: Border.all(
          //                 color: Color.fromRGBO(255, 255, 255, 0.12),
          //               ),
          //             ),
          //             child: const Icon(Icons.camera_alt, color: Colors.white),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Do not dispose central CameraController here; managed by cameraProvider
    _barcodeScanner?.close();
    super.dispose();
  }
}
