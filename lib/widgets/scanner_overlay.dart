import 'package:flutter/material.dart';

/// ScannerOverlay draws a translucent overlay with a centered cutout
/// and an animated horizontal scan line. Use it on top of a camera
/// preview inside a Stack.
///
/// Example:
/// Stack(
///   children: [
///     CameraPreview(controller),
///     const ScannerOverlay(),
///   ],
/// )
class ScannerOverlay extends StatefulWidget {
  final double cutOutWidth;
  final double cutOutHeight;
  final double borderRadius;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;
  final Color scanLineColor;
  final double scanLineHeight;
  final Duration duration;
  final EdgeInsets padding;

  const ScannerOverlay({
    super.key,
    this.cutOutWidth = 300,
    this.cutOutHeight = 220,
    this.borderRadius = 12,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.45),
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.scanLineColor = const Color(0xFF00E676),
    this.scanLineHeight = 3,
    this.duration = const Duration(milliseconds: 2000),
    this.padding = const EdgeInsets.all(24),
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Center the cutout inside the available area (respecting padding)
        final maxW = constraints.maxWidth - widget.padding.horizontal;
        final maxH = constraints.maxHeight - widget.padding.vertical;
        final cutW = widget.cutOutWidth.clamp(0.0, maxW);
        final cutH = widget.cutOutHeight.clamp(0.0, maxH);

        return Stack(
          children: [
            // dark overlay with hole
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OverlayPainter(
                holeWidth: cutW,
                holeHeight: cutH,
                borderRadius: widget.borderRadius,
                overlayColor: widget.overlayColor,
                borderColor: widget.borderColor,
                borderWidth: widget.borderWidth,
                padding: widget.padding,
              ),
            ),

            // animated scan line positioned over the hole
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final t = _animation.value; // 0..1
                  final top =
                      widget.padding.top +
                      (maxH - cutH) / 2 +
                      t * (cutH - widget.scanLineHeight);
                  final left = widget.padding.left + (maxW - cutW) / 2;
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        width: cutW,
                        height: widget.scanLineHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.scanLineColor.withValues(alpha: 0.0),
                                widget.scanLineColor.withValues(alpha: 0.95),
                                widget.scanLineColor.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // optional shimmer glow just above/below the line
                      Positioned(
                        left: left,
                        top: top - 1,
                        width: cutW,
                        height: widget.scanLineHeight + 2,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.25,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.scanLineColor.withValues(alpha: 0.0),
                                    widget.scanLineColor.withValues(alpha: 0.4),
                                    widget.scanLineColor.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // small corner brackets for style
            Positioned.fill(
              child: IgnorePointer(
                child: _CornerBrackets(
                  cutOutWidth: cutW,
                  cutOutHeight: cutH,
                  borderRadius: widget.borderRadius,
                  padding: widget.padding,
                  color: widget.borderColor,
                  strokeWidth: 4,
                  length: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double holeWidth;
  final double holeHeight;
  final double borderRadius;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  _OverlayPainter({
    required this.holeWidth,
    required this.holeHeight,
    required this.borderRadius,
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final left =
        padding.left + (size.width - padding.horizontal - holeWidth) / 2;
    final top = padding.top + (size.height - padding.vertical - holeHeight) / 2;
    final holeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, holeWidth, holeHeight),
      Radius.circular(borderRadius),
    );

    final hole = Path()..addRRect(holeRect);
    final path = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(path, paint);

    // draw border around hole
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(holeRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBrackets extends StatelessWidget {
  final double cutOutWidth;
  final double cutOutHeight;
  final double borderRadius;
  final EdgeInsets padding;
  final Color color;
  final double strokeWidth;
  final double length;

  const _CornerBrackets({
    required this.cutOutWidth,
    required this.cutOutHeight,
    required this.borderRadius,
    required this.padding,
    required this.color,
    required this.strokeWidth,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left =
            padding.left +
            (constraints.maxWidth - padding.horizontal - cutOutWidth) / 2;
        final top =
            padding.top +
            (constraints.maxHeight - padding.vertical - cutOutHeight) / 2;
        return Stack(
          children: [
            // top-left
            Positioned(
              left: left - strokeWidth / 2,
              top: top - strokeWidth / 2,
              child: CustomPaint(
                size: Size(length, length),
                painter: _BracketPainter(
                  color: color,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            // top-right
            Positioned(
              left: left + cutOutWidth - length + strokeWidth / 2,
              top: top - strokeWidth / 2,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(3.14159 / 2),
                child: CustomPaint(
                  size: Size(length, length),
                  painter: _BracketPainter(
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
            // bottom-left
            Positioned(
              left: left - strokeWidth / 2,
              top: top + cutOutHeight - length + strokeWidth / 2,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(-3.14159 / 2),
                child: CustomPaint(
                  size: Size(length, length),
                  painter: _BracketPainter(
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
            // bottom-right
            Positioned(
              left: left + cutOutWidth - length + strokeWidth / 2,
              top: top + cutOutHeight - length + strokeWidth / 2,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(3.14159),
                child: CustomPaint(
                  size: Size(length, length),
                  painter: _BracketPainter(
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _BracketPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // draw an L shaped bracket
    path.moveTo(0, size.height * 0.6);
    path.lineTo(0, 0);
    path.lineTo(size.width * 0.6, 0);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
