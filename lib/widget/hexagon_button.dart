import 'package:flutter/material.dart';

class HexagonButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback? onPressed;
  final Widget child;
  final Color borderColor;
  final Color glowColor;
  final Color backgroundColor;

  const HexagonButton({
    super.key,
    required this.width,
    required this.height,
    required this.onPressed,
    required this.child,
    required this.borderColor,
    required this.glowColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // painter for neon border
          SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: HexagonPainter(
                borderColor: borderColor,
                glowColor: glowColor,
              ),
            ),
          ),
          // clipped button surface
          ClipPath(
            clipper: HexagonClipper(),
            child: Material(
              color: backgroundColor,
              child: InkWell(
                onTap: onPressed,
                child: Center(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    // Regular hexagon points
    path.moveTo(w * 0.10, 0);
    path.lineTo(w * 0.90, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.90, h);
    path.lineTo(w * 0.10, h);
    path.lineTo(0, h * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HexagonPainter extends CustomPainter {
  final Color borderColor;
  final Color glowColor;

  HexagonPainter({required this.borderColor, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = borderColor;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(size.width * 0.10, 0);
    path.lineTo(size.width * 0.90, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.90, size.height);
    path.lineTo(size.width * 0.10, size.height);
    path.lineTo(0, size.height * 0.5);
    path.close();

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
