import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notifier that centralizes CameraController lifecycle and common helpers.
class CameraNotifier extends Notifier<CameraController?> {
  bool _isInitializing = false;

  @override
  CameraController? build() {
    return null;
  }

  bool get isInitializing => _isInitializing;

  bool get isInitialized => state != null && state!.value.isInitialized;

  /// Initialize camera once. If already initializing/initialized this returns.
  Future<void> initializeCamera({
    CameraLensDirection preferred = CameraLensDirection.back,
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    if (_isInitializing || isInitialized) return;
    _isInitializing = true;
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final res = await Permission.camera.request();
        if (!res.isGranted) {
          debugPrint('Camera permission denied');
          return;
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Choose camera by preferred direction if available
      CameraDescription selected = cameras.first;
      for (final c in cameras) {
        if (c.lensDirection == preferred) {
          selected = c;
          break;
        }
      }

      final controller = CameraController(selected, preset, enableAudio: false);
      await controller.initialize();
      if (ref.mounted) {
        state = controller;
      } else {
        // If not mounted, dispose created controller
        await controller.dispose();
      }
    } catch (e, st) {
      debugPrint('CameraNotifier initialize error: $e\n$st');
    } finally {
      _isInitializing = false;
    }
  }

  /// Take picture via central controller. Returns null if controller not ready.
  Future<XFile?> takePicture() async {
    final c = state;
    if (c == null || !c.value.isInitialized) return null;
    try {
      return await c.takePicture();
    } catch (e) {
      debugPrint('CameraNotifier takePicture error: $e');
      return null;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    final c = state;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(mode);
    } catch (e) {
      debugPrint('setFlashMode error: $e');
    }
  }

  Future<void> pausePreview() async {
    final c = state;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.pausePreview();
    } catch (e) {
      debugPrint('pausePreview error: $e');
    }
  }

  Future<void> resumePreview() async {
    final c = state;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.resumePreview();
    } catch (e) {
      debugPrint('resumePreview error: $e');
    }
  }

  Future<void> stopImageStream() async {
    final c = state;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.stopImageStream();
    } catch (e) {
      debugPrint('stopImageStream error: $e');
    }
  }

  /// Dispose the controller and clear state. Call when you want to release camera globally.
  Future<void> disposeController() async {
    final c = state;
    if (c == null) return;
    try {
      await c.dispose();
    } catch (e) {
      debugPrint('disposeController error: $e');
    } finally {
      state = null;
    }
  }
}

final cameraProvider = NotifierProvider<CameraNotifier, CameraController?>(
  () => CameraNotifier(),
);
