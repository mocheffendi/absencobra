import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

// provider to expose whether the DetectorView camera has been initialized
class DetectorInitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInitialized(bool v) => state = v;
}

final detectorViewInitProvider = NotifierProvider<DetectorInitNotifier, bool>(
  () => DetectorInitNotifier(),
);

class DetectorView extends ConsumerStatefulWidget {
  const DetectorView({
    super.key,
    required this.title,
    required this.onImage,
    this.customPaint,
    this.text,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
  });

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  ConsumerState<DetectorView> createState() => _DetectorViewState();
}

class _DetectorViewState extends ConsumerState<DetectorView> {
  CameraController? _controller;
  int _cameraIndex = -1;
  CameraLensDirection _currentCameraLensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _currentCameraLensDirection = widget.initialCameraLensDirection;
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Find camera with the desired lens direction
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == _currentCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }

    if (_cameraIndex != -1) {
      _controller = CameraController(
        cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      // Start image stream for real-time processing
      await _controller!.startImageStream(_processCameraImage);

      if (mounted) {
        // mark initialized via provider to trigger rebuild without local setState
        ref.read(detectorViewInitProvider.notifier).setInitialized(true);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_controller == null) return;

    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    _currentCameraLensDirection =
        _currentCameraLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await _controller!.dispose();
    _controller = null;

    widget.onCameraLensDirectionChanged?.call(_currentCameraLensDirection);
    await _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      widget.onImage(inputImage);
    } catch (e) {
      // Silently handle image processing errors to avoid spam
      debugPrint('Error processing camera image: $e');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // For Android, use NV21 format which is more common
    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    // Use the first plane for processing
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  Widget build(BuildContext context) {
    final initialized = ref.watch(detectorViewInitProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.switch_camera, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
          // Camera preview
          _controller?.value.isInitialized == true && initialized
              ? CameraPreview(_controller!)
              : const Center(child: CircularProgressIndicator()),
          // Custom paint overlay
          if (widget.customPaint != null) widget.customPaint!,
          // Text overlay
          if (widget.text != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: Text(
                  widget.text!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
