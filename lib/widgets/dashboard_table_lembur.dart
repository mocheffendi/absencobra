import 'package:cobra_apps/providers/lembur_provider.dart';
import 'package:flutter/material.dart';

/// Reusable dashboard table showing recent absen entries.
class DashboardTableLembur extends StatelessWidget {
  final String title;
  final List<String> headers;
  final LemburData lemburData;

  const DashboardTableLembur({
    super.key,
    required this.title,
    required this.headers,
    required this.lemburData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                outside: BorderSide(
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  children: headers
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            h,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (lemburData.isLoading)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      const SizedBox(),
                      const SizedBox(),
                    ],
                  )
                else if (lemburData.absensi7.isEmpty)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Tidak ada data',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(),
                      const SizedBox(),
                    ],
                  )
                else
                  ...lemburData.absensi7.map(
                    (r) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            r['tanggal'] ?? '-',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            r['in'] ?? '-',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            r['out'] ?? '-',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
