import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to hold transient page-level states (e.g., absen page cek mode data)
class AbsenPageNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setCekModeData(Map<String, dynamic>? data) {
    state = data;
  }

  void clear() => state = null;
}

final absenPageProvider =
    NotifierProvider<AbsenPageNotifier, Map<String, dynamic>?>(
      () => AbsenPageNotifier(),
    );

// Provider for ScanMasuk page transient state
class ScanMasukState {
  final bool cameraInitialized;
  final String? lastCode;
  final PositionData? currentPosition;
  final String? address;
  final Map<String, dynamic>? qrLocation;
  final double? distanceMeters;
  final Map<String, dynamic>? qrValidationResult;
  final bool isValidating;
  final String? validationError;
  final bool navigated;

  const ScanMasukState({
    this.cameraInitialized = false,
    this.lastCode,
    this.currentPosition,
    this.address,
    this.qrLocation,
    this.distanceMeters,
    this.qrValidationResult,
    this.isValidating = false,
    this.validationError,
    this.navigated = false,
  });

  ScanMasukState copyWith({
    bool? cameraInitialized,
    String? lastCode,
    PositionData? currentPosition,
    String? address,
    Map<String, dynamic>? qrLocation,
    double? distanceMeters,
    Map<String, dynamic>? qrValidationResult,
    bool? isValidating,
    String? validationError,
    bool? navigated,
  }) {
    return ScanMasukState(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      lastCode: lastCode ?? this.lastCode,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      qrLocation: qrLocation ?? this.qrLocation,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      qrValidationResult: qrValidationResult ?? this.qrValidationResult,
      isValidating: isValidating ?? this.isValidating,
      validationError: validationError ?? this.validationError,
      navigated: navigated ?? this.navigated,
    );
  }
}

class PositionData {
  final double latitude;
  final double longitude;
  const PositionData(this.latitude, this.longitude);
}

class ScanMasukNotifier extends Notifier<ScanMasukState> {
  @override
  ScanMasukState build() => const ScanMasukState();

  void setCameraInitialized(bool v) =>
      state = state.copyWith(cameraInitialized: v);
  void setLastCode(String? c) => state = state.copyWith(lastCode: c);
  void setCurrentPosition(PositionData? p) =>
      state = state.copyWith(currentPosition: p);
  void setAddress(String? a) => state = state.copyWith(address: a);
  void setQrLocation(Map<String, dynamic>? loc) =>
      state = state.copyWith(qrLocation: loc);
  void setDistanceMeters(double? d) =>
      state = state.copyWith(distanceMeters: d);
  void setQrValidationResult(Map<String, dynamic>? r) =>
      state = state.copyWith(qrValidationResult: r);
  void setIsValidating(bool v) => state = state.copyWith(isValidating: v);
  void setValidationError(String? e) =>
      state = state.copyWith(validationError: e);
  void setNavigated(bool v) => state = state.copyWith(navigated: v);
}

final scanMasukProvider = NotifierProvider<ScanMasukNotifier, ScanMasukState>(
  () => ScanMasukNotifier(),
);
