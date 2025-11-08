import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

// Provider to hold loaded PDF bytes for preview
class PdfBytesNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void setBytes(Uint8List? b) => state = b;
}

final pdfBytesProvider = NotifierProvider<PdfBytesNotifier, Uint8List?>(
  () => PdfBytesNotifier(),
);

class PdfPreviewPage extends ConsumerStatefulWidget {
  final String filePath;
  const PdfPreviewPage({super.key, required this.filePath});

  @override
  ConsumerState<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends ConsumerState<PdfPreviewPage> {
  @override
  void initState() {
    super.initState();
    File(widget.filePath).readAsBytes().then((bytes) {
      if (mounted) {
        ref.read(pdfBytesProvider.notifier).setBytes(bytes);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sharePdf() async {
    // await SharePlus.shareXFiles([XFile(widget.filePath)], text: 'Slip Gaji');
    await SharePlus.instance.share(
      ShareParams(text: 'Slip Gaji', files: [XFile(widget.filePath)]),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final src = File(widget.filePath);
      if (!await src.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('File tidak ditemukan')));
        }
        return;
      }

      // Prefer a user-visible Downloads folder inside app documents
      final baseDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}Downloads',
      );
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = File(widget.filePath).uri.pathSegments.last;
      final destPath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';
      await src.copy(destPath);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File disimpan: $destPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal simpan file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // penting agar background terlihat di bawah BottomAppBar
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Use flexibleSpace to layer a frosted glass effect that blurs
        // the background image beneath the AppBar, creating an acrylic look.
        // flexibleSpace: ClipRect(
        //   child: BackdropFilter(
        //     filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        //     child: Container(
        //       color: Colors.white.withValues(
        //         alpha: 0.12,
        //       ), // tint over blurred bg
        //     ),
        //   ),
        // ),
        title: const Text('Slip Gaji', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _downloadPdf),
          IconButton(icon: const Icon(Icons.share), onPressed: _sharePdf),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
          ),
          // reduced overlay so background remains visible through frosted elements
          Positioned.fill(
            child: Container(
              // subtle dark tint so content remains readable
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          SafeArea(
            child: Builder(
              builder: (context) {
                final bytes = ref.watch(pdfBytesProvider);
                return bytes == null
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        color: Colors.transparent,
                        child: PdfViewer.data(
                          bytes,
                          sourceName: widget.filePath,
                          params: const PdfViewerParams(
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
