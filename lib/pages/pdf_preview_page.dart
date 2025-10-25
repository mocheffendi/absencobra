import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewPage extends StatefulWidget {
  final String filePath;
  const PdfPreviewPage({super.key, required this.filePath});

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    File(widget.filePath).readAsBytes().then((bytes) {
      if (mounted) {
        setState(() => _pdfBytes = bytes);
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
            child: _pdfBytes == null
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    color: Colors.transparent,
                    child: _pdfBytes == null
                        ? const Center(child: CircularProgressIndicator())
                        : PdfViewer.data(
                            _pdfBytes!,
                            sourceName: widget.filePath,
                            params: const PdfViewerParams(
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
