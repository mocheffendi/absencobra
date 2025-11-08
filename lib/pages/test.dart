// import 'dart:developer';

import 'package:cobra_apps/widgets/barcode_detector_painter.dart';
import 'package:cobra_apps/widgets/detector_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import '../providers/user_provider.dart';
// import '../utility/shared_prefs_util.dart';

// Providers for transient test page UI state
class TestTextNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setText(String? t) => state = t;
}

final testTextProvider = NotifierProvider<TestTextNotifier, String?>(
  () => TestTextNotifier(),
);

class TestCustomPaintNotifier extends Notifier<CustomPaint?> {
  @override
  CustomPaint? build() => null;
  void setPaint(CustomPaint? p) => state = p;
}

final testCustomPaintProvider =
    NotifierProvider<TestCustomPaintNotifier, CustomPaint?>(
      () => TestCustomPaintNotifier(),
    );

class TestIsBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setBusy(bool v) => state = v;
}

final testIsBusyProvider = NotifierProvider<TestIsBusyNotifier, bool>(
  () => TestIsBusyNotifier(),
);

class TestCameraLensNotifier extends Notifier<CameraLensDirection> {
  @override
  CameraLensDirection build() => CameraLensDirection.back;
  void setDirection(CameraLensDirection d) => state = d;
}

final testCameraLensDirectionProvider =
    NotifierProvider<TestCameraLensNotifier, CameraLensDirection>(
      () => TestCameraLensNotifier(),
    );

class TestPage extends ConsumerStatefulWidget {
  const TestPage({super.key});

  @override
  ConsumerState<TestPage> createState() => _TestPageState();
}

class _TestPageState extends ConsumerState<TestPage> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _canProcess = true;

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Barcode Scanner',
      customPaint: ref.watch(testCustomPaintProvider),
      text: ref.watch(testTextProvider),
      onImage: _processImage,
      initialCameraLensDirection: ref.watch(testCameraLensDirectionProvider),
      onCameraLensDirectionChanged: (value) => ref
          .read(testCameraLensDirectionProvider.notifier)
          .setDirection(value),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (ref.read(testIsBusyProvider)) return;
    ref.read(testIsBusyProvider.notifier).setBusy(true);
    ref.read(testTextProvider.notifier).setText('');
    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = BarcodeDetectorPainter(
        barcodes,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        ref.read(testCameraLensDirectionProvider),
      );
      ref
          .read(testCustomPaintProvider.notifier)
          .setPaint(CustomPaint(painter: painter));
    } else {
      String text = 'Barcodes found: ${barcodes.length}\n\n';
      for (final barcode in barcodes) {
        text += 'Barcode: ${barcode.rawValue}\n\n';
      }
      ref.read(testTextProvider.notifier).setText(text);
      // TODO: set paint to draw boundingRect on top of image
      ref.read(testCustomPaintProvider.notifier).setPaint(null);
    }
    ref.read(testIsBusyProvider.notifier).setBusy(false);
  }
  // // Map<String, dynamic>? _cekModeData;

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     // only load cek_mod_absen and route according to server rules
  //     // await _loadCekModeData();

  //     await _loadPrefs();
  //   });
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  // Future<void> _loadPrefs() async {
  //   final map = await SharedPrefsUtil.loadAllPrefs();
  //   final user = await SharedPrefsUtil.loadUser();
  //   ref.read(prefsProvider.notifier).state = map;
  //   ref.read(userPrefsProvider.notifier).state = user;

  //   log('id_pegawai: ${user?.id_pegawai}');
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     extendBodyBehindAppBar: true,
  //     resizeToAvoidBottomInset: false,
  //     backgroundColor: Colors.transparent,
  //     appBar: AppBar(
  //       toolbarHeight: 50,
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       centerTitle: true,

  //       title: const Text('Test'),
  //     ),
  //     body: Stack(
  //       children: [
  //         Positioned.fill(
  //           child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
  //         ),
  //         // reduced overlay so background remains visible through frosted elements
  //         Positioned.fill(
  //           child: Container(
  //             // subtle dark tint so content remains readable
  //             color: Colors.black.withValues(alpha: 0.15),
  //           ),
  //         ),
  //         // SafeArea(
  //         //   child: Center(
  //         //     child: Padding(
  //         //       padding: const EdgeInsets.all(16.0),
  //         //       child: Column(
  //         //         mainAxisSize: MainAxisSize.min,
  //         //         children: [
  //         //           const CircularProgressIndicator(),
  //         //           const SizedBox(height: 12),
  //         //           const Text('Memeriksa mode absen...'),
  //         //           const SizedBox(height: 16),
  //         //           if (_cekModeData != null) ...[
  //         //             Text('next_mod: ${_cekModeData!['next_mod'] ?? ''}'),
  //         //             Text(
  //         //               'jenis_aturan: ${_cekModeData!['jenis_aturan'] ?? ''}',
  //         //             ),
  //         //             Text('status: ${_cekModeData!['status'] ?? ''}'),
  //         //             const SizedBox(height: 8),
  //         //             Text('${_cekModeData!['message'] ?? ''}'),
  //         //           ],
  //         //           const SizedBox(height: 16),
  //         //           // ElevatedButton(
  //         //           //   onPressed: _startCekFlow,
  //         //           //   child: const Text('Retry'),
  //         //           // ),
  //         //         ],
  //         //       ),
  //         //     ),
  //         //   ),
  //         // ),
  //       ],
  //     ),
  //   );
  // }
}
