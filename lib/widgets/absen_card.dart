import 'package:flutter/material.dart';
import 'package:cobra_apps/providers/absen_provider.dart';

/// Reusable Absen card used on the dashboard.
class AbsenCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final AbsenData absenData;

  const AbsenCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.absenData,
  });

  @override
  Widget build(BuildContext context) {
    if (absenData.isLoading) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.7)),
          ),
          height: 135,
          padding: const EdgeInsets.all(8),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.7)),
        ),
        height: 135,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Icon(icon, color: color, size: 30)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title.contains('Masuk')
                  ? (absenData.wktMasukToday ?? "__:__:__")
                  : (title.contains('Pulang')
                        ? (absenData.wktPulangToday ?? "__:__:__")
                        : "__:__:__"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
