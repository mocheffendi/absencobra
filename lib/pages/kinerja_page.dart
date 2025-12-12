// import 'package:flutter/material.dart';

// class KinerjaPage extends StatefulWidget {
//   const KinerjaPage({super.key});

//   @override
//   State<KinerjaPage> createState() => _KinerjaPageState();
// }

// class _KinerjaPageState extends State<KinerjaPage> {
//   // Map<String, dynamic>? _cekModeData;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       // only load cek_mod_absen and route according to server rules
//       // await _loadCekModeData();
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         toolbarHeight: 50,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         // Use flexibleSpace to layer a frosted glass effect that blurs
//         // the background image beneath the AppBar, creating an acrylic look.
//         // flexibleSpace: ClipRect(
//         //   child: BackdropFilter(
//         //     filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
//         //     child: Container(
//         //       color: Colors.white.withValues(
//         //         alpha: 0.12,
//         //       ), // tint over blurred bg
//         //     ),
//         //   ),
//         // ),
//         title: const Text('Kinerja Pegawai'),
//       ),
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset('assets/jpg/bg_blur.jpg', fit: BoxFit.cover),
//           ),
//           // reduced overlay so background remains visible through frosted elements
//           Positioned.fill(
//             child: Container(
//               // subtle dark tint so content remains readable
//               color: Colors.black.withValues(alpha: 0.15),
//             ),
//           ),
//           // SafeArea(
//           //   child: Center(
//           //     child: Padding(
//           //       padding: const EdgeInsets.all(16.0),
//           //       child: Column(
//           //         mainAxisSize: MainAxisSize.min,
//           //         children: [
//           //           const CircularProgressIndicator(),
//           //           const SizedBox(height: 12),
//           //           const Text('Memeriksa mode absen...'),
//           //           const SizedBox(height: 16),
//           //           if (_cekModeData != null) ...[
//           //             Text('next_mod: ${_cekModeData!['next_mod'] ?? ''}'),
//           //             Text(
//           //               'jenis_aturan: ${_cekModeData!['jenis_aturan'] ?? ''}',
//           //             ),
//           //             Text('status: ${_cekModeData!['status'] ?? ''}'),
//           //             const SizedBox(height: 8),
//           //             Text('${_cekModeData!['message'] ?? ''}'),
//           //           ],
//           //           const SizedBox(height: 16),
//           //           // ElevatedButton(
//           //           //   onPressed: _startCekFlow,
//           //           //   child: const Text('Retry'),
//           //           // ),
//           //         ],
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utility/shared_prefs_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class KinerjaPage extends StatefulWidget {
  const KinerjaPage({super.key});

  @override
  State<KinerjaPage> createState() => _KinerjaPageState();
}

class _KinerjaPageState extends State<KinerjaPage> {
  final TextEditingController uraianController = TextEditingController();

  File? beforeImage;
  File? afterImage;

  bool isLoading = false;

  final picker = ImagePicker();

  // 🔥 Fungsi untuk kompres file JPG
  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();

    final targetPath = p.join(
      dir.path,
      "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 300,
      minHeight: 300,
      format: CompressFormat.jpeg,
    );

    // jika gagal compress, tetap kembalikan file asli
    return File(result?.path ?? file.path);
  }

  Future<void> pickImageFor({required bool isBefore}) async {
    // Ask user whether to take a new photo or pick from gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Batal'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return; // user cancelled

    final XFile? file = await picker.pickImage(source: source);
    if (file != null) {
      File compressed = await compressImage(File(file.path));
      setState(() {
        if (isBefore) {
          beforeImage = compressed;
        } else {
          afterImage = compressed;
        }
      });
    }
  }

  Future<void> uploadKinerja() async {
    if (uraianController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uraian wajib diisi")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // get token from shared preferences
      final token = await SharedPrefsUtil.getPref('token') as String?;
      log("Token: $token");

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Token tidak ditemukan")));
        setState(() => isLoading = false);
        return;
      }

      final uri = Uri.parse(
        'https://absencobra.cbsguard.co.id/api/kinerja_api.php',
      );
      var request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      request.fields["uraian"] = uraianController.text;

      if (beforeImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("before", beforeImage!.path),
        );
      }

      if (afterImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("after", afterImage!.path),
        );
      }

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Berhasil: $body")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $body")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Input Kinerja"),
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Uraian"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: uraianController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Foto (Before / After)"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Before', textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => pickImageFor(isBefore: true),
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: beforeImage == null
                                    ? const Center(
                                        child: Text("Tap untuk ambil foto"),
                                      )
                                    : Image.file(
                                        beforeImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('After', textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => pickImageFor(isBefore: false),
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: afterImage == null
                                    ? const Center(
                                        child: Text("Tap untuk ambil foto"),
                                      )
                                    : Image.file(
                                        afterImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : uploadKinerja,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Kirim Kinerja"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
