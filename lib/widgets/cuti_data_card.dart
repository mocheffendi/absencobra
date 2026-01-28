import 'dart:ui';
import 'package:flutter/material.dart';

class CutiDataCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CutiDataCard({super.key, required this.data});

  String _labelJenis(dynamic val) {
    switch (val?.toString()) {
      case '1':
        return 'Cuti Tahunan';
      case '2':
        return 'Cuti Melahirkan';
      case '3':
        return 'Sakit';
      case '4':
        return 'Izin Karena Alasan Penting';
      case '5':
        return 'Izin Berduka';
      default:
        return val?.toString() ?? '-';
    }
  }

  String _labelStatus(dynamic st) {
    if (st == null) return '-';
    if (st.toString() == '1') return 'Disetujui';
    if (st.toString() == '0') return 'Ditolak';
    return st.toString();
  }

  Color _statusColor(dynamic st) {
    if (st == null) return Colors.grey;
    if (st.toString() == '1') return Colors.green;
    if (st.toString() == '0') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: (() {
                final url = d['lampiran_url']?.toString();
                if (url == null || url.isEmpty)
                  return const Icon(Icons.insert_drive_file);
                if (url.toLowerCase().endsWith('.pdf')) {
                  return const Icon(Icons.picture_as_pdf, color: Colors.red);
                }
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox.shrink(),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                    (progress
                                                            .expectedTotalBytes ??
                                                        1)
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      url,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                );
              }()),
              title: Text(_labelJenis(d['jenis_cuti'])),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal mulai cuti: ${d['tgl'] ?? ''}'),
                  Text('Tanggal selesai cuti: ${d['tgl_sampai'] ?? ''}'),
                  if ((d['ket'] ?? '').toString().isNotEmpty)
                    Text('Ket: ${d['ket']}'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(_labelStatus(d['st'])),
                        backgroundColor: _statusColor(
                          d['st'],
                        ).withValues(alpha: 0.12),
                        labelStyle: TextStyle(color: _statusColor(d['st'])),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class CutiDataCard extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const CutiDataCard({super.key, required this.data});

//   String _labelJenis(dynamic val) {
//     switch (val?.toString()) {
//       case '1':
//         return 'Cuti Tahunan';
//       case '2':
//         return 'Cuti Melahirkan';
//       case '3':
//         return 'Sakit';
//       case '4':
//         return 'Izin Karena Alasan Penting';
//       case '5':
//         return 'Izin Berduka';
//       default:
//         return val?.toString() ?? '-';
//     }
//   }

//   String _labelStatus(dynamic st) {
//     if (st == null) return '-';
//     if (st.toString() == '1') return 'Disetujui';
//     if (st.toString() == '0') return 'Ditolak';
//     return st.toString();
//   }

//   Color _statusColor(dynamic st) {
//     if (st == null) return Colors.grey;
//     if (st.toString() == '1') return Colors.green;
//     if (st.toString() == '0') return Colors.red;
//     return Colors.grey;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final d = data;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.white.withOpacity(0.06),
//                   Colors.white.withOpacity(0.02),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.white.withOpacity(0.12)),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 8,
//               ),
//               leading: (() {
//                 final url = d['lampiran_url']?.toString();
//                 if (url == null || url.isEmpty)
//                   return const Icon(Icons.insert_drive_file);
//                 if (url.toLowerCase().endsWith('.pdf')) {
//                   return const Icon(Icons.picture_as_pdf, color: Colors.red);
//                 }
//                 return GestureDetector(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (_) => Dialog(
//                         insetPadding: const EdgeInsets.all(16),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const SizedBox.shrink(),
//                                   IconButton(
//                                     icon: const Icon(Icons.close),
//                                     onPressed: () =>
//                                         Navigator.of(context).pop(),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Flexible(
//                               child: InteractiveViewer(
//                                 panEnabled: true,
//                                 minScale: 0.5,
//                                 maxScale: 4.0,
//                                 child: Image.network(
//                                   url,
//                                   fit: BoxFit.contain,
//                                   loadingBuilder: (context, child, progress) {
//                                     if (progress == null) return child;
//                                     return SizedBox(
//                                       height: 200,
//                                       child: Center(
//                                         child: CircularProgressIndicator(
//                                           value:
//                                               progress.expectedTotalBytes !=
//                                                   null
//                                               ? progress.cumulativeBytesLoaded /
//                                                     (progress
//                                                             .expectedTotalBytes ??
//                                                         1)
//                                               : null,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   errorBuilder: (context, error, stack) =>
//                                       const SizedBox(
//                                         height: 200,
//                                         child: Center(
//                                           child: Icon(Icons.broken_image),
//                                         ),
//                                       ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: Image.network(
//                       url,
//                       width: 48,
//                       height: 48,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stack) =>
//                           const Icon(Icons.broken_image),
//                     ),
//                   ),
//                 );
//               }()),
//               title: Text(_labelJenis(d['jenis_cuti'])),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Tanggal mulai cuti: ${d['tgl'] ?? ''}'),
//                   Text('Tanggal selesai cuti: ${d['tgl_sampai'] ?? ''}'),
//                   if ((d['ket'] ?? '').toString().isNotEmpty)
//                     Text('Ket: ${d['ket']}'),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Chip(
//                         label: Text(_labelStatus(d['st'])),
//                         backgroundColor: _statusColor(
//                           d['st'],
//                         ).withOpacity(0.12),
//                         labelStyle: TextStyle(color: _statusColor(d['st'])),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
