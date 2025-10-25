import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Widget buildFrostedIconButton(
  IconData icon, {
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: 44,
    height: 44,
    child: ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onPressed,
            child: Center(child: Icon(icon, color: Colors.white)),
          ),
        ),
      ),
    ),
  );
}
