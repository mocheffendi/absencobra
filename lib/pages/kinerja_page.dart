import 'package:flutter/material.dart';

class KinerjaPage extends StatefulWidget {
  const KinerjaPage({super.key});

  @override
  State<KinerjaPage> createState() => _KinerjaPageState();
}

class _KinerjaPageState extends State<KinerjaPage> {
  // Map<String, dynamic>? _cekModeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // only load cek_mod_absen and route according to server rules
      // await _loadCekModeData();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        title: const Text('Kinerja Pegawai'),
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
          // SafeArea(
          //   child: Center(
          //     child: Padding(
          //       padding: const EdgeInsets.all(16.0),
          //       child: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           const CircularProgressIndicator(),
          //           const SizedBox(height: 12),
          //           const Text('Memeriksa mode absen...'),
          //           const SizedBox(height: 16),
          //           if (_cekModeData != null) ...[
          //             Text('next_mod: ${_cekModeData!['next_mod'] ?? ''}'),
          //             Text(
          //               'jenis_aturan: ${_cekModeData!['jenis_aturan'] ?? ''}',
          //             ),
          //             Text('status: ${_cekModeData!['status'] ?? ''}'),
          //             const SizedBox(height: 8),
          //             Text('${_cekModeData!['message'] ?? ''}'),
          //           ],
          //           const SizedBox(height: 16),
          //           // ElevatedButton(
          //           //   onPressed: _startCekFlow,
          //           //   child: const Text('Retry'),
          //           // ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
