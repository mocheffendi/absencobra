import 'package:flutter/material.dart';

bool _obscurePassword = true;

Widget buildCyanField({
  required TextEditingController controller,
  required String label,
  IconData? prefix,
  bool obscure = false,
  bool toggle = false,
  VoidCallback? onToggle,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: prefix != null
          ? Icon(prefix, color: Colors.cyanAccent)
          : null,
      suffixIcon: toggle
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: onToggle,
            )
          : null,
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.cyanAccent.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.cyanAccent.shade400, width: 2),
      ),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return '$label tidak boleh kosong';
      return null;
    },
  );
}
