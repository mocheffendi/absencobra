import 'package:flutter/material.dart';

/// Full-screen scanner overlay: single glowing horizontal scan line that moves
/// vertically across the entire area. No framed cutout — intended to be placed
/// above a CameraPreview (e.g. Positioned.fill(child: QrisScannerAnimation())).
class QrisScannerAnimation extends StatefulWidget {
  const QrisScannerAnimation({super.key});

  /// Duration for a full up->down->up cycle.
  final Duration duration = const Duration(milliseconds: 1400);

  @override
  State<QrisScannerAnimation> createState() => _QrisScannerAnimationState();
}

class _QrisScannerAnimationState extends State<QrisScannerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final height = constraints.maxHeight;
                const lineHeight = 8.0;
                final t = CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ).value;
                final top = (height - lineHeight) * t;

                return Stack(
                  children: [
                    // transparent background so overlay doesn't block camera input
                    Positioned.fill(
                      child: Container(color: Colors.transparent),
                    ),

                    // animated horizontal scan line — use a single solid cyan line with layered glow
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: lineHeight,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.95),
                          boxShadow: [
                            // close subtle glow
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.45),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                            // wider faint bluish glow
                            BoxShadow(
                              color: Colors.lightBlueAccent.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
