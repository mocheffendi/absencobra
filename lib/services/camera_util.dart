import 'package:camera/camera.dart';
import 'dart:developer';
import 'package:flutter/material.dart';

class CameraUtil {
  static Future<CameraController?> initFrontCamera({
    required BuildContext context,
    ResolutionPreset preset = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada kamera tersedia')),
        );
        return null;
      }
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCamera,
        preset,
        enableAudio: enableAudio,
      );
      await controller.initialize();
      return controller;
    } on CameraException catch (e) {
      log('CameraException: ${e.code} - ${e.description}');
      String errorMessage = 'Gagal mengakses kamera';
      switch (e.code) {
        case 'CameraAccessDenied':
          errorMessage =
              'Akses kamera ditolak. Berikan izin kamera di pengaturan aplikasi';
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          errorMessage =
              'Akses kamera ditolak. Buka pengaturan aplikasi untuk memberikan izin';
          break;
        case 'CameraAccessRestricted':
          errorMessage = 'Akses kamera dibatasi oleh sistem';
          break;
        case 'cameraPermission':
          errorMessage =
              'Izin kamera diperlukan. Restart aplikasi setelah memberikan izin';
          break;
        case 'AudioAccessDenied':
          errorMessage =
              'Izin microphone diperlukan untuk akses kamera. Berikan izin microphone di pengaturan aplikasi';
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          errorMessage =
              'Izin microphone diperlukan untuk akses kamera. Buka pengaturan aplikasi untuk memberikan izin';
          break;
        case 'AudioAccessRestricted':
          errorMessage = 'Akses microphone dibatasi oleh sistem';
          break;
        default:
          errorMessage = 'Error kamera: ${e.code}';
      }
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Pengaturan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Buka Pengaturan > Aplikasi > AbsenCobra > Izin > Kamera & Microphone',
                  ),
                ),
              );
            },
          ),
        ),
      );
      return null;
    } catch (e) {
      log('Camera init unexpected error: $e');
      String errorMessage = 'Gagal inisialisasi kamera';
      if (e.toString().contains('No cameras found')) {
        errorMessage = 'Tidak ada kamera tersedia di device ini';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage =
            'Error platform kamera. Pastikan device mendukung kamera';
      }
      if (!context.mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return null;
    }
  }
}
