import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeDetectorPainter extends CustomPainter {
  BarcodeDetectorPainter(
    this.barcodes,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<Barcode> barcodes;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = const Color(0x99000000);

    for (final Barcode barcode in barcodes) {
      final Rect boundingBox = _calculateBoundingBox(
        barcode.boundingBox,
        absoluteImageSize,
        rotation,
        size,
        cameraLensDirection,
      );

      canvas.drawRect(boundingBox, paint);
      canvas.drawRect(
        Rect.fromLTRB(
          boundingBox.left - 8,
          boundingBox.top - 8,
          boundingBox.left +
              (barcode.rawValue?.length ?? 0).toDouble() * 20 +
              8,
          boundingBox.top - 24,
        ),
        background,
      );

      final textSpan = TextSpan(
        text: barcode.rawValue,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(boundingBox.left - 4, boundingBox.top - 24),
      );
    }
  }

  Rect _calculateBoundingBox(
    Rect? boundingBox,
    Size absoluteImageSize,
    InputImageRotation rotation,
    Size size,
    CameraLensDirection cameraLensDirection,
  ) {
    if (boundingBox == null) {
      return Rect.zero;
    }

    double left = boundingBox.left;
    double top = boundingBox.top;
    double right = boundingBox.right;
    double bottom = boundingBox.bottom;

    // Handle rotation
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        final temp = left;
        left = absoluteImageSize.height - bottom;
        bottom = right;
        right = absoluteImageSize.height - top;
        top = temp;
        break;
      case InputImageRotation.rotation270deg:
        final temp = left;
        left = top;
        top = absoluteImageSize.width - right;
        right = bottom;
        bottom = absoluteImageSize.width - temp;
        break;
      case InputImageRotation.rotation180deg:
        left = absoluteImageSize.width - right;
        right = absoluteImageSize.width - left;
        top = absoluteImageSize.height - bottom;
        bottom = absoluteImageSize.height - top;
        break;
      default:
        // No rotation needed
        break;
    }

    // Handle camera lens direction
    if (cameraLensDirection == CameraLensDirection.front) {
      left = absoluteImageSize.width - right;
      right = absoluteImageSize.width - left;
    }

    // Scale to canvas size
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    return Rect.fromLTRB(
      left * scaleX,
      top * scaleY,
      right * scaleX,
      bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(BarcodeDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.barcodes != barcodes;
  }
}
