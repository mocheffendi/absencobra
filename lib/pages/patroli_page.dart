import 'package:camera/camera.dart';
import 'package:cobra_apps/widgets/barcode_detector_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:cobra_apps/pages/patrol_photo_page.dart';
import 'package:cobra_apps/pages/detector_view.dart';
import 'package:cobra_apps/widgets/scanner_overlay2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/patrol_provider.dart';

class PatroliPage extends ConsumerStatefulWidget {
  const PatroliPage({super.key});

  @override
  ConsumerState<PatroliPage> createState() => _PatroliPageState();
}

class _PatroliPageState extends ConsumerState<PatroliPage> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patrolState = ref.watch(patrolProvider);
    final currentAddress = patrolState.currentAddress;
    final currentPosition = patrolState.currentPosition;
    ref.listen<String?>(patrolErrorProvider, (previous, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
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
        title: const Text(
          "Patroli Scan QRCode",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          DetectorView(
            title: 'Barcode Scanner',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
          ),
          Positioned.fill(child: QrisScannerAnimation()),
          Positioned(
            left: 12,
            bottom: 24,
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
                          'Lat: \\${currentPosition.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Long: \\${currentPosition.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            "Lokasi: \\${currentAddress}",
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
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final barcodes = await _barcodeScanner.processImage(inputImage);
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
      String text = 'Barcodes found: \\${barcodes.length}\n\n';
      for (final barcode in barcodes) {
        text += 'Barcode: \\${barcode.rawValue}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    // Jika barcode ditemukan, langsung navigasi ke PatrolPhotoPage
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      if (mounted) {
        _canProcess = false;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatrolPhotoPage(qrId: code)),
        );
        _canProcess = true;
      }
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
