import 'package:cobra_apps/services/applog.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraUtil {
  /// Initializes the front camera and returns the CameraController if successful.
  /// Shows detailed snackbar on error using the provided context.
  /// Calls onReady callback when camera is ready (only if context is still mounted).
  static Future<CameraController?> tryInitCamera(
    BuildContext context,
    VoidCallback onReady, {
    bool useFrontCamera = true,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada kamera tersedia')),
          );
        }
        return null;
      }

      // Use the front camera or fallback to first camera
      final selectedCamera = useFrontCamera
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.first;

      final controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: enableAudio,
      );

      await controller.initialize();

      if (context.mounted) {
        onReady();
      }
      return controller;
    } on CameraException catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'camera_util',
        action: 'camera_exception',
        message: 'CameraException: ${e.code} ${e.description}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal akses kamera: ${e.code}')),
        );
      }
      return null;
    } catch (e) {
      LogService.log(
        level: 'ERROR',
        source: 'camera_util',
        action: 'init_error',
        message: 'camera init error: $e',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal inisialisasi kamera')),
        );
      }
      return null;
    }
  }
}
