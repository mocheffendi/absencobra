import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cobra_apps/utility/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// Model untuk patrol data
class PatrolData {
  final String id;
  final String qrId;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String status;
  final String fotoUrl;

  PatrolData({
    required this.id,
    required this.qrId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.status,
    this.fotoUrl = '',
  });

  factory PatrolData.fromJson(Map<String, dynamic> json) {
    // Handle both formats: new patrol data (with lat/lng) and stored patrol data (from API)
    if (json.containsKey('id_patroli')) {
      // Format from get_patroli.php API
      final tanggal = json['tanggal']?.toString() ?? '';
      final jam = json['jam']?.toString() ?? '';
      final dateTimeStr = jam.isNotEmpty ? '$tanggal $jam' : tanggal;

      return PatrolData(
        id: json['id_patroli']?.toString() ?? '',
        qrId:
            json['nama_pin']?.toString() ?? json['nama_tmpt']?.toString() ?? '',
        latitude: 0.0, // Not available in stored data
        longitude: 0.0, // Not available in stored data
        address: json['nama_tmpt']?.toString() ?? '',
        timestamp: DateTime.tryParse(dateTimeStr) ?? DateTime.now(),
        status: json['keterangan']?.toString() ?? '',
        fotoUrl: json['foto1']?.toString() ?? '',
      );
    } else {
      // Original format for new patrol data
      return PatrolData(
        id: json['id']?.toString() ?? '',
        qrId: json['qr_id']?.toString() ?? '',
        latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
        longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
        address: json['address']?.toString() ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        status: json['status']?.toString() ?? '',
        fotoUrl: json['foto1']?.toString() ?? '',
      );
    }
  }
}

// State untuk patrol
class PatrolState {
  final List<PatrolData> patrolList;
  final bool isLoading;
  final String? error;
  final Position? currentPosition;
  final String? currentAddress;
  final bool isScanning;
  final bool isProcessingScan;

  const PatrolState({
    this.patrolList = const [],
    this.isLoading = false,
    this.error,
    this.currentPosition,
    this.currentAddress,
    this.isScanning = false,
    this.isProcessingScan = false,
  });

  PatrolState copyWith({
    List<PatrolData>? patrolList,
    bool? isLoading,
    String? error,
    Position? currentPosition,
    String? currentAddress,
    bool? isScanning,
    bool? isProcessingScan,
  }) {
    return PatrolState(
      patrolList: patrolList ?? this.patrolList,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      isScanning: isScanning ?? this.isScanning,
      isProcessingScan: isProcessingScan ?? this.isProcessingScan,
    );
  }
}

// Patrol Notifier
class PatrolNotifier extends Notifier<PatrolState> {
  @override
  PatrolState build() {
    return const PatrolState();
  }

  // Get current location and address
  Future<void> getCurrentLocation() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(error: "Layanan lokasi belum aktif");
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          state = state.copyWith(error: "Izin lokasi ditolak");
          return;
        }
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      // Get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "";
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }

      state = state.copyWith(
        currentPosition: position,
        currentAddress: address,
        error: null,
      );
    } catch (e) {
      log('Location error: $e');
      state = state.copyWith(
        error: "Gagal mendapatkan lokasi: ${e.toString()}",
        currentAddress: "Gagal mendapatkan alamat",
      );
    }
  }

  // Send patrol data to backend
  Future<void> sendPatrolData(String qrData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.currentPosition == null) {
        await getCurrentLocation();
        if (state.currentPosition == null) {
          state = state.copyWith(
            isLoading: false,
            error: "Lokasi tidak tersedia",
          );
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      User? user;
      if (userJson != null) {
        try {
          user = User.fromJson(json.decode(userJson));
        } catch (e) {
          log('Error parsing user data in sendPatrolData: $e');
        }
      }

      if (user == null || user.token == null || user.token!.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: "Token autentikasi tidak tersedia",
        );
        return;
      }

      final token = user.token!;

      final response = await http.post(
        Uri.parse("$kBaseApiUrl/patrol_api.php"),
        headers: {"Authorization": "Bearer $token"},
        body: {"qr_id": qrData},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        log("Patrol response: $result");

        // Add to patrol list
        final newPatrol = PatrolData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          qrId: qrData,
          latitude: state.currentPosition!.latitude,
          longitude: state.currentPosition!.longitude,
          address: state.currentAddress ?? '',
          timestamp: DateTime.now(),
          status: result["message"] ?? "Success",
        );

        state = state.copyWith(
          patrolList: [...state.patrolList, newPatrol],
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Gagal kirim data, code: ${response.statusCode}",
        );
      }
    } on SocketException catch (e) {
      log("Patrol network error: $e");
      state = state.copyWith(
        isLoading: false,
        error:
            'Internet is disconnected, please check your internet connection',
      );
    } on http.ClientException catch (e) {
      log("Patrol client error: $e");
      state = state.copyWith(
        isLoading: false,
        error:
            'Internet is disconnected, please check your internet connection',
      );
    } catch (e) {
      log("Patrol error: $e");
      state = state.copyWith(
        isLoading: false,
        error: "Gagal kirim data: ${e.toString()}",
      );
    }
  }

  // Fetch patrol history
  Future<void> fetchPatrolHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      User? user;
      if (userJson != null) {
        try {
          user = User.fromJson(json.decode(userJson));
        } catch (e) {
          log('Error parsing user data in fetchPatrolHistory: $e');
        }
      }

      if (user == null || user.token == null || user.token!.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: "Token autentikasi tidak tersedia",
        );
        return;
      }

      final token = user.token!;
      log('Fetching patrol history with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse("$kBaseApiUrl/get_patroli.php"),
        headers: {"Authorization": "Bearer $token"},
      );

      log('Patrol history response status: ${response.statusCode}');
      log('Patrol history response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("Fetch patrol data: $data");
        if (data['success'] == true || data['success'] == 'true') {
          final List<PatrolData> patrolList = (data['data'] as List)
              .map((item) => PatrolData.fromJson(item))
              .toList();

          // Sort by timestamp (newest first) and limit to the most recent 7 rows
          patrolList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final limitedPatrolList = patrolList.take(7).toList();

          log('Successfully loaded ${limitedPatrolList.length} patrol records (limited to 7)');

          state = state.copyWith(
            patrolList: limitedPatrolList,
            isLoading: false,
            error: null,
          );
        } else {
          log('API returned error: ${data['message']}');
          state = state.copyWith(
            isLoading: false,
            error: data['message'] ?? 'Gagal mengambil data patrol',
          );
        }
      } else {
        log('HTTP error: ${response.statusCode}');
        state = state.copyWith(
          isLoading: false,
          error: "Server error: ${response.statusCode}",
        );
      }
    } on SocketException catch (e) {
      log("Fetch patrol network error: $e");
      state = state.copyWith(
        isLoading: false,
        error:
            'Internet is disconnected, please check your internet connection',
      );
    } on http.ClientException catch (e) {
      log("Fetch patrol client error: $e");
      state = state.copyWith(
        isLoading: false,
        error:
            'Internet is disconnected, please check your internet connection',
      );
    } catch (e) {
      log("Fetch patrol error: $e");
      state = state.copyWith(
        isLoading: false,
        error: "Gagal mengambil data: ${e.toString()}",
      );
    }
  }

  // Set scanning state
  void setScanning(bool isScanning) {
    state = state.copyWith(isScanning: isScanning);
  }

  // Set processing scan state
  void setProcessingScan(bool isProcessing) {
    state = state.copyWith(isProcessingScan: isProcessing);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider untuk PatrolNotifier
final patrolProvider = NotifierProvider<PatrolNotifier, PatrolState>(() {
  return PatrolNotifier();
});

// Provider untuk patrol list
final patrolListProvider = Provider<List<PatrolData>>((ref) {
  return ref.watch(patrolProvider).patrolList;
});

// Provider untuk current position
final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(patrolProvider).currentPosition;
});

// Provider untuk current address
final currentAddressProvider = Provider<String?>((ref) {
  return ref.watch(patrolProvider).currentAddress;
});

// Provider untuk loading status
final patrolLoadingProvider = Provider<bool>((ref) {
  return ref.watch(patrolProvider).isLoading;
});

// Provider untuk error
final patrolErrorProvider = Provider<String?>((ref) {
  return ref.watch(patrolProvider).error;
});

// Provider untuk processing scan state
final processingScanProvider = Provider<bool>((ref) {
  return ref.watch(patrolProvider).isProcessingScan;
});
