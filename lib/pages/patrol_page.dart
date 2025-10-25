import 'package:absencobra/pages/patrol_photo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../providers/patrol_provider.dart';

class PatrolPage extends ConsumerStatefulWidget {
  const PatrolPage({super.key});

  @override
  ConsumerState<PatrolPage> createState() => _PatrolPageState();
}

class _PatrolPageState extends ConsumerState<PatrolPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for scanning line
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Get current location when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patrolProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
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
        // Clear error after showing in the next frame to avoid provider rebuild
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
        // Use flexibleSpace to layer a frosted glass effect that blurs
        // the background image beneath the AppBar, creating an acrylic look.
        // flexibleSpace: ClipRect(
        //   child: BackdropFilter(
        //     filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        //     child: Container(
        //       color: Colors.white.withValues(
        //         alpha: 0.12,
        //       ), // tint over blurred bg
        //     ),
        //   ),
        // ),
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
          // reduced overlay so background remains visible through frosted elements
          Positioned.fill(
            child: Container(
              // subtle dark tint so content remains readable
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Main column holds QRView and the Scan Ulang button
                Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          QRView(
                            key: qrKey,
                            onQRViewCreated: _onQRViewCreated,
                            overlay: QrScannerOverlayShape(
                              borderColor: Colors.green,
                              borderRadius: 10,
                              borderLength: 30,
                              borderWidth: 10,
                              cutOutSize: 250,
                            ),
                          ),
                          // Animated scanning line
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Positioned(
                                top:
                                    MediaQuery.of(context).size.height * 0.15 +
                                    (_animation.value *
                                        550), // Adjust based on QR viewfinder position
                                left: MediaQuery.of(context).size.width * 0.2,
                                right: MediaQuery.of(context).size.width * 0.2,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.red.withValues(alpha: 0.8),
                                        Colors.red,
                                        Colors.red.withValues(alpha: 0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // removed inline Scan Ulang button; moved to bottom-center
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
                            controller?.resumeCamera();
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

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (!ref.read(processingScanProvider)) {
        ref.read(patrolProvider.notifier).setProcessingScan(true);
        controller?.pauseCamera();
        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatrolPhotoPage(qrId: scanData.code ?? ''),
          ),
        );
        if (result == true) {
          if (!mounted) return;
          Navigator.pop(context, true); // kembali ke Dashboard, trigger refresh
        } else {
          ref.read(patrolProvider.notifier).setProcessingScan(false);
          controller?.resumeCamera();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.stopCamera();
    super.dispose();
  }
}
