// import 'dart:io';
// import 'dart:ui' as ui;

// import 'package:absencobra/pages/dashboard_page_riverpod.dart';
// import 'package:absencobra/utility/settings.dart';
// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:absencobra/pages/absen_masuk_page.dart';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class ScanMasukPage extends StatefulWidget {
//   final Map<String, dynamic>? data;
//   const ScanMasukPage({super.key, this.data});

//   @override
//   State<ScanMasukPage> createState() => _ScanMasukPageState();
// }

// class _ScanMasukPageState extends State<ScanMasukPage> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   String? _lastCode;
//   Position? _currentPosition;
//   String? _address;
//   Map<String, dynamic>? _qrLocation; // {lat, lon}
//   double? _distanceMeters;
//   Map<String, dynamic>? _qrValidationResult;
//   bool _isValidating = false;
//   String? _validationError;
//   bool _navigated = false;

//   Future<void> _resolveAddress(Position pos) async {
//     try {
//       final p = await placemarkFromCoordinates(pos.latitude, pos.longitude);
//       if (p.isNotEmpty) {
//         final pm = p.first;
//         final parts = <String>[];
//         if (pm.name != null && pm.name!.isNotEmpty) parts.add(pm.name!);
//         if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
//           parts.add(pm.subLocality!);
//         }
//         if (pm.locality != null && pm.locality!.isNotEmpty) {
//           parts.add(pm.locality!);
//         }
//         if (pm.administrativeArea != null &&
//             pm.administrativeArea!.isNotEmpty) {
//           parts.add(pm.administrativeArea!);
//         }
//         if (pm.country != null && pm.country!.isNotEmpty) {
//           parts.add(pm.country!);
//         }
//         final addr = parts.join(', ');
//         if (!mounted) return;
//         setState(() => _address = addr);
//       }
//     } catch (e) {
//       // ignore
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // Prevent automatic pop
//       onPopInvokedWithResult: (bool didPop, Object? result) async {
//         if (didPop) return; // If already popped, do nothing
//         // Custom logic without dialog
//         bool canPop = /* your condition here, e.g., */
//             true; // Replace with your logic
//         if (canPop) {
//           // Navigator.of(context).pop(); // Manually pop if condition is met
//           _goToDashboard();
//         }
//       },
//       child: Scaffold(
//         extendBodyBehindAppBar: true,
//         resizeToAvoidBottomInset: false,
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           toolbarHeight: 50,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           centerTitle: true,
//           // Use flexibleSpace to layer a frosted glass effect that blurs
//           // the background image beneath the AppBar, creating an acrylic look.
//           flexibleSpace: ClipRect(
//             child: BackdropFilter(
//               filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
//               child: Container(
//                 color: Colors.white.withValues(
//                   alpha: 0.12,
//                 ), // tint over blurred bg
//               ),
//             ),
//           ),
//           title: const Text(
//             'Scan Masuk',
//             style: TextStyle(color: Colors.white),
//           ),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () async => await _goToDashboard(),
//           ),
//         ),
//         body: Stack(
//           children: [
//             Positioned.fill(
//               child: Image.asset('assets/jpg/bg.jpg', fit: BoxFit.cover),
//             ),
//             // Frosted glass overlay: blur the background image beneath the content
//             Positioned.fill(
//               child: ClipRect(
//                 child: BackdropFilter(
//                   filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
//                   child: Container(
//                     // subtle dark tint so content remains readable
//                     color: Colors.black.withValues(alpha: 0.12),
//                   ),
//                 ),
//               ),
//             ),
//             SafeArea(
//               child: Column(
//                 children: <Widget>[
//                   Expanded(
//                     child: Stack(
//                       children: [
//                         Positioned.fill(
//                           child: QRView(
//                             key: qrKey,
//                             overlay: QrScannerOverlayShape(
//                               borderColor: Colors.white,
//                               borderRadius: 8,
//                               borderLength: 24,
//                               borderWidth: 6,
//                               cutOutSize: 280,
//                             ),
//                             onQRViewCreated: (QRViewController c) {
//                               controller = c;
//                               controller!.scannedDataStream.listen((
//                                 scanData,
//                               ) async {
//                                 final code = scanData.code;
//                                 if (code != null && code != _lastCode) {
//                                   setState(() {
//                                     _lastCode = code;
//                                     log('Scanned QR Code: $code');
//                                     _isValidating = true;
//                                     _qrValidationResult = null;
//                                     _validationError = null;
//                                   });

//                                   try {
//                                     final prefs =
//                                         await SharedPreferences.getInstance();
//                                     final idPegawai =
//                                         prefs.getString('id_pegawai') ?? '1';
//                                     final jenis =
//                                         'masuk'; // or 'pulang' for absen pulang

//                                     log(
//                                       'Validating QR with body: ${jsonEncode({'qr': code, 'id_pegawai': idPegawai, 'jenis': jenis})}',
//                                     );
//                                     final url = Uri.parse(
//                                       '$kBaseUrl/include/validasi_qr.php',
//                                     );

//                                     final resp = await http.post(
//                                       url,
//                                       headers: {
//                                         'Content-Type':
//                                             'application/json; charset=utf-8',
//                                         'Accept': 'application/json',
//                                       },
//                                       body: jsonEncode({
//                                         'qr': code,
//                                         'id_pegawai': idPegawai,
//                                         'jenis': jenis,
//                                       }),
//                                     );
//                                     if (resp.statusCode == 200) {
//                                       Map<String, dynamic>? data;
//                                       try {
//                                         final body = resp.body.trim();
//                                         if (body.isEmpty) {
//                                           // Empty response — don't throw, record and continue
//                                           log(
//                                             'QR validation empty response body="${resp.body}"',
//                                           );
//                                           data = {
//                                             'success': false,
//                                             'message':
//                                                 'Empty response from server',
//                                           };
//                                         } else {
//                                           final parsed = jsonDecode(body);
//                                           if (parsed is Map<String, dynamic>) {
//                                             data = parsed;
//                                           } else if (parsed is List &&
//                                               parsed.isNotEmpty &&
//                                               parsed.first is Map) {
//                                             data = Map<String, dynamic>.from(
//                                               parsed.first as Map,
//                                             );
//                                           } else {
//                                             // not a map; wrap into a generic response
//                                             data = {
//                                               'success': false,
//                                               'message':
//                                                   'Invalid response format',
//                                             };
//                                           }
//                                         }
//                                       } catch (e) {
//                                         log(
//                                           'QR validation parse error: $e body="${resp.body}"',
//                                         );
//                                         data = {
//                                           'success': false,
//                                           'message': 'Invalid server response',
//                                         };
//                                       }
//                                       setState(() {
//                                         _qrValidationResult = data;
//                                         _isValidating = false;
//                                         if (data != null &&
//                                             data['success'] != true) {
//                                           _validationError =
//                                               data['message']?.toString() ??
//                                               'Invalid server response';
//                                         }
//                                       });
//                                       // --- AUTO NAVIGATE LOGIC ---
//                                       // Only navigate if not already navigated
//                                       if (!_navigated &&
//                                           data['success'] == true) {
//                                         // Use distance from validation result if available, else from _distanceMeters
//                                         double? maxDistance;
//                                         if (data['max'] != null) {
//                                           maxDistance = double.tryParse(
//                                             data['max'].toString(),
//                                           );
//                                         }
//                                         // Calculate distance to validation location
//                                         double? distance;
//                                         final latStr = data['latitude']
//                                             ?.toString();
//                                         final lonStr = data['longitude']
//                                             ?.toString();
//                                         final lat = latStr != null
//                                             ? double.tryParse(latStr)
//                                             : null;
//                                         final lon = lonStr != null
//                                             ? double.tryParse(lonStr)
//                                             : null;
//                                         if (lat != null &&
//                                             lon != null &&
//                                             _currentPosition != null) {
//                                           distance = Geolocator.distanceBetween(
//                                             lat,
//                                             lon,
//                                             _currentPosition!.latitude,
//                                             _currentPosition!.longitude,
//                                           );
//                                         } else {
//                                           distance = _distanceMeters;
//                                         }
//                                         if (maxDistance != null &&
//                                             distance != null &&
//                                             distance <= maxDistance) {
//                                           _navigated = true;
//                                           // Defer navigation to next frame to avoid using
//                                           // BuildContext across async gaps.
//                                           WidgetsBinding.instance
//                                               .addPostFrameCallback((_) {
//                                                 if (!mounted) return;
//                                                 Navigator.of(
//                                                   context,
//                                                 ).pushReplacement(
//                                                   MaterialPageRoute(
//                                                     builder: (_) =>
//                                                         AbsenMasukPage(
//                                                           data: data,
//                                                         ),
//                                                   ),
//                                                 );
//                                               });
//                                         }
//                                       }
//                                       // --- END AUTO NAVIGATE LOGIC ---
//                                     } else {
//                                       setState(() {
//                                         _validationError =
//                                             'Status ${resp.statusCode}: ${resp.body}';
//                                         _isValidating = false;
//                                       });
//                                       log(
//                                         'QR validation failed: ${resp.statusCode} ${resp.body}',
//                                       );
//                                     }
//                                   } catch (e) {
//                                     setState(() {
//                                       _validationError = 'Error: $e';
//                                       _isValidating = false;
//                                     });
//                                     log('QR validation error: $e');
//                                   }
//                                 }
//                               });
//                             },
//                           ),
//                         ),
//                         // location overlay top-left + QR data + distance
//                         Positioned(
//                           left: 12,
//                           top: 12,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black54,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: _currentPosition != null
//                                 ? Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                       Text(
//                                         'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                       if (_address != null)
//                                         SizedBox(
//                                           width: 180,
//                                           child: Text(
//                                             _address!,
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 11,
//                                             ),
//                                             maxLines: 2,
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         )
//                                       else
//                                         const Text(
//                                           'Mencari alamat...',
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       const SizedBox(height: 8),
//                                     ],
//                                   )
//                                 : const Text(
//                                     'Mencari lokasi...',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 12,
//                           bottom: 12,
//                           child: Column(
//                             children: [
//                               if (_lastCode != null)
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'QR Data: $_lastCode',
//                                       style: const TextStyle(
//                                         color: Colors.yellow,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                     if (_qrLocation != null)
//                                       Text(
//                                         'QR Lokasi: lat=${_qrLocation!['lat']}, lon=${_qrLocation!['lon']}',
//                                         style: const TextStyle(
//                                           color: Colors.cyanAccent,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     if (_distanceMeters != null)
//                                       Text(
//                                         'Jarak ke QR: ${_distanceMeters!.toStringAsFixed(1)} meter',
//                                         style: const TextStyle(
//                                           color: Colors.orangeAccent,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     const SizedBox(height: 8),
//                                     if (_isValidating)
//                                       const Text(
//                                         'Validasi QR...',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     if (_validationError != null)
//                                       Text(
//                                         _validationError!,
//                                         style: const TextStyle(
//                                           color: Colors.redAccent,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               // validasi_qr result overlay kiri bawah
//                               if (_qrValidationResult != null)
//                                 Builder(
//                                   builder: (context) {
//                                     double? distance;
//                                     final latStr =
//                                         _qrValidationResult!['latitude']
//                                             ?.toString();
//                                     final lonStr =
//                                         _qrValidationResult!['longitude']
//                                             ?.toString();
//                                     final lat = latStr != null
//                                         ? double.tryParse(latStr)
//                                         : null;
//                                     final lon = lonStr != null
//                                         ? double.tryParse(lonStr)
//                                         : null;
//                                     if (lat != null &&
//                                         lon != null &&
//                                         _currentPosition != null) {
//                                       distance = Geolocator.distanceBetween(
//                                         lat,
//                                         lon,
//                                         _currentPosition!.latitude,
//                                         _currentPosition!.longitude,
//                                       );
//                                     }
//                                     return Container(
//                                       margin: const EdgeInsets.only(top: 4),
//                                       padding: const EdgeInsets.all(8),
//                                       decoration: BoxDecoration(
//                                         color: Colors.black38,
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           const Text(
//                                             'Hasil Validasi QR:',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 13,
//                                             ),
//                                           ),
//                                           ..._qrValidationResult!.entries.map(
//                                             (e) => Text(
//                                               '${e.key}: ${e.value}',
//                                               style: TextStyle(
//                                                 color: e.key == 'success'
//                                                     ? (e.value == true
//                                                           ? Colors.greenAccent
//                                                           : Colors.redAccent)
//                                                     : Colors.white,
//                                                 fontWeight: e.key == 'success'
//                                                     ? FontWeight.bold
//                                                     : FontWeight.normal,
//                                                 fontSize: 12,
//                                               ),
//                                             ),
//                                           ),
//                                           if (distance != null)
//                                             Padding(
//                                               padding: const EdgeInsets.only(
//                                                 top: 4,
//                                               ),
//                                               child: Text(
//                                                 'Jarak ke lokasi validasi: ${distance.toStringAsFixed(1)} meter',
//                                                 style: const TextStyle(
//                                                   color: Colors.orangeAccent,
//                                                   fontSize: 13,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                             ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                             ],
//                           ),
//                         ),
//                         // Flash button overlay top right
//                         Positioned(
//                           top: 12,
//                           right: 12,
//                           child: Material(
//                             color: Colors.transparent,
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(24),
//                               onTap: () async {
//                                 await controller?.toggleFlash();
//                                 if (mounted) {
//                                   // ignore: use_build_context_synchronously
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text('Flash toggled'),
//                                     ),
//                                   );
//                                 }
//                               },
//                               child: Ink(
//                                 decoration: BoxDecoration(
//                                   color: Colors.black54,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Padding(
//                                   padding: EdgeInsets.all(10),
//                                   child: Icon(
//                                     Icons.flash_on,
//                                     color: Colors.yellow,
//                                     size: 28,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _goToDashboard() async {
//     try {
//       // stop camera first
//       await controller?.pauseCamera();
//       // controller?.dispose(); // Disposing the QRViewController is no longer necessary
//     } catch (_) {}
//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const DashboardPageRiverpod()),
//       (route) => false,
//     );
//   }
// }

import 'dart:io';

import 'package:absencobra/utility/settings.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:absencobra/pages/dashboard_page.dart';
import 'package:absencobra/pages/absen_masuk_page.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScanMasukPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ScanMasukPage({super.key, this.data});

  @override
  State<ScanMasukPage> createState() => _ScanMasukPageState();
}

class _ScanMasukPageState extends State<ScanMasukPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? _lastCode;
  Position? _currentPosition;
  String? _address;
  Map<String, dynamic>? _qrLocation; // {lat, lon}
  double? _distanceMeters;
  Map<String, dynamic>? _qrValidationResult;
  bool _isValidating = false;
  String? _validationError;
  bool _navigated = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    // controller?.dispose(); // Disposing the QRViewController is no longer necessary
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureAndGetLocation();
    });
  }

  Future<void> _ensureAndGetLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _resolveAddress(pos);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _resolveAddress(Position pos) async {
    try {
      final p = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (p.isNotEmpty) {
        final pm = p.first;
        final parts = <String>[];
        if (pm.name != null && pm.name!.isNotEmpty) parts.add(pm.name!);
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
          parts.add(pm.subLocality!);
        }
        if (pm.locality != null && pm.locality!.isNotEmpty) {
          parts.add(pm.locality!);
        }
        if (pm.administrativeArea != null &&
            pm.administrativeArea!.isNotEmpty) {
          parts.add(pm.administrativeArea!);
        }
        if (pm.country != null && pm.country!.isNotEmpty) {
          parts.add(pm.country!);
        }
        final addr = parts.join(', ');
        if (!mounted) return;
        setState(() => _address = addr);
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic pop
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // If already popped, do nothing
        // Custom logic without dialog
        bool canPop = /* your condition here, e.g., */
            true; // Replace with your logic
        if (canPop) {
          // Navigator.of(context).pop(); // Manually pop if condition is met
          _goToDashboard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Masuk'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async => await _goToDashboard(),
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: QRView(
                      key: qrKey,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.white,
                        borderRadius: 8,
                        borderLength: 24,
                        borderWidth: 6,
                        cutOutSize: 280,
                      ),
                      onQRViewCreated: (QRViewController c) {
                        controller = c;
                        controller!.scannedDataStream.listen((scanData) async {
                          final code = scanData.code;
                          if (code != null && code != _lastCode) {
                            setState(() {
                              _lastCode = code;
                              log('Scanned QR Code: $code');
                              _isValidating = true;
                              _qrValidationResult = null;
                              _validationError = null;
                            });

                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final idPegawai =
                                  prefs.getString('idpegawai') ?? '1';
                              final jenis =
                                  'masuk'; // or 'pulang' for absen pulang
                              final url = Uri.parse(
                                '$kBaseUrl/include/validasi_qr.php',
                              );
                              final resp = await http.post(
                                url,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'qr': code,
                                  'id_pegawai': idPegawai,
                                  'jenis': jenis,
                                }),
                              );
                              if (resp.statusCode == 200) {
                                final data = jsonDecode(resp.body);
                                setState(() {
                                  _qrValidationResult = data;
                                  _isValidating = false;
                                });
                                // --- AUTO NAVIGATE LOGIC ---
                                // Only navigate if not already navigated
                                if (!_navigated && data['success'] == true) {
                                  // Use distance from validation result if available, else from _distanceMeters
                                  double? maxDistance;
                                  if (data['max'] != null) {
                                    maxDistance = double.tryParse(
                                      data['max'].toString(),
                                    );
                                  }
                                  // Calculate distance to validation location
                                  double? distance;
                                  final latStr = data['latitude']?.toString();
                                  final lonStr = data['longitude']?.toString();
                                  final lat = latStr != null
                                      ? double.tryParse(latStr)
                                      : null;
                                  final lon = lonStr != null
                                      ? double.tryParse(lonStr)
                                      : null;
                                  if (lat != null &&
                                      lon != null &&
                                      _currentPosition != null) {
                                    distance = Geolocator.distanceBetween(
                                      lat,
                                      lon,
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    );
                                  } else {
                                    distance = _distanceMeters;
                                  }
                                  if (maxDistance != null &&
                                      distance != null &&
                                      distance <= maxDistance) {
                                    _navigated = true;
                                    if (!mounted) return;
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AbsenMasukPage(data: data),
                                      ),
                                    );
                                  }
                                }
                                // --- END AUTO NAVIGATE LOGIC ---
                              } else {
                                setState(() {
                                  _validationError =
                                      'Status ${resp.statusCode}: ${resp.body}';
                                  _isValidating = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _validationError = 'Error: $e';
                                _isValidating = false;
                              });
                            }
                          }
                        });
                      },
                    ),
                  ),
                  // location overlay top-left + QR data + distance
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _currentPosition != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                if (_address != null)
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      _address!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Mencari alamat...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            )
                          : const Text(
                              'Mencari lokasi...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Column(
                      children: [
                        if (_lastCode != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'QR Data: $_lastCode',
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                ),
                              ),
                              if (_qrLocation != null)
                                Text(
                                  'QR Lokasi: lat=${_qrLocation!['lat']}, lon=${_qrLocation!['lon']}',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              if (_distanceMeters != null)
                                Text(
                                  'Jarak ke QR: ${_distanceMeters!.toStringAsFixed(1)} meter',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (_isValidating)
                                const Text(
                                  'Validasi QR...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              if (_validationError != null)
                                Text(
                                  _validationError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        // validasi_qr result overlay kiri bawah
                        if (_qrValidationResult != null)
                          Builder(
                            builder: (context) {
                              double? distance;
                              final latStr = _qrValidationResult!['latitude']
                                  ?.toString();
                              final lonStr = _qrValidationResult!['longitude']
                                  ?.toString();
                              final lat = latStr != null
                                  ? double.tryParse(latStr)
                                  : null;
                              final lon = lonStr != null
                                  ? double.tryParse(lonStr)
                                  : null;
                              if (lat != null &&
                                  lon != null &&
                                  _currentPosition != null) {
                                distance = Geolocator.distanceBetween(
                                  lat,
                                  lon,
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                );
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hasil Validasi QR:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    ..._qrValidationResult!.entries.map(
                                      (e) => Text(
                                        '${e.key}: ${e.value}',
                                        style: TextStyle(
                                          color: e.key == 'success'
                                              ? (e.value == true
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                              : Colors.white,
                                          fontWeight: e.key == 'success'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (distance != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Jarak ke lokasi validasi: ${distance.toStringAsFixed(1)} meter',
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Flash button overlay top right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          await controller?.toggleFlash();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Flash toggled')),
                          );
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.yellow,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToDashboard() async {
    try {
      // stop camera first
      await controller?.pauseCamera();
      // controller?.dispose(); // Disposing the QRViewController is no longer necessary
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }
}
