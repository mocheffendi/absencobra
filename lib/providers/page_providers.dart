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
  final int? lastCodeTimestamp;
  final PositionData? currentPosition;
  final String? address;
  final Map<String, dynamic>? qrLocation;
  final double? distanceMeters;
  final Map<String, dynamic>? qrValidationResult;
  final bool isValidating;
  final String? validationError;
  final bool navigated;
  final bool isScanning;

  const ScanMasukState({
    this.cameraInitialized = false,
    this.lastCode,
    this.lastCodeTimestamp,
    this.currentPosition,
    this.address,
    this.qrLocation,
    this.distanceMeters,
    this.qrValidationResult,
    this.isValidating = false,
    this.validationError,
    this.navigated = false,
    this.isScanning = false,
  });

  ScanMasukState copyWith({
    bool? cameraInitialized,
    String? lastCode,
    int? lastCodeTimestamp,
    PositionData? currentPosition,
    String? address,
    Map<String, dynamic>? qrLocation,
    double? distanceMeters,
    Map<String, dynamic>? qrValidationResult,
    bool? isValidating,
    String? validationError,
    bool? navigated,
    bool? isScanning,
  }) {
    return ScanMasukState(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      lastCode: lastCode ?? this.lastCode,
      lastCodeTimestamp: lastCodeTimestamp ?? this.lastCodeTimestamp,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      qrLocation: qrLocation ?? this.qrLocation,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      qrValidationResult: qrValidationResult ?? this.qrValidationResult,
      isValidating: isValidating ?? this.isValidating,
      validationError: validationError ?? this.validationError,
      navigated: navigated ?? this.navigated,
      isScanning: isScanning ?? this.isScanning,
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
  void setLastCodeWithTimestamp(String? c) => state = state.copyWith(
    lastCode: c,
    lastCodeTimestamp: c == null ? null : DateTime.now().millisecondsSinceEpoch,
  );
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
  void setIsScanning(bool v) => state = state.copyWith(isScanning: v);
  void clear() => state = const ScanMasukState();
}

final scanMasukProvider = NotifierProvider<ScanMasukNotifier, ScanMasukState>(
  () => ScanMasukNotifier(),
);

// Provider for ScanPulang page transient state
class ScanPulangState {
  final bool cameraInitialized;
  final String? lastCode;
  final PositionData? currentPosition;
  final int? lastCodeTimestamp;
  final String? address;
  final Map<String, dynamic>? qrLocation;
  final double? distanceMeters;
  final Map<String, dynamic>? qrValidationResult;
  final bool isValidating;
  final String? validationError;
  final bool navigated;
  final bool isScanning;

  const ScanPulangState({
    this.cameraInitialized = false,
    this.lastCode,
    this.currentPosition,
    this.lastCodeTimestamp,
    this.address,
    this.qrLocation,
    this.distanceMeters,
    this.qrValidationResult,
    this.isValidating = false,
    this.validationError,
    this.navigated = false,
    this.isScanning = false,
  });

  ScanPulangState copyWith({
    bool? cameraInitialized,
    String? lastCode,
    int? lastCodeTimestamp,
    PositionData? currentPosition,
    String? address,
    Map<String, dynamic>? qrLocation,
    double? distanceMeters,
    Map<String, dynamic>? qrValidationResult,
    bool? isValidating,
    String? validationError,
    bool? navigated,
    bool? isScanning,
  }) {
    return ScanPulangState(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      lastCode: lastCode ?? this.lastCode,
      lastCodeTimestamp: lastCodeTimestamp ?? this.lastCodeTimestamp,
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      qrLocation: qrLocation ?? this.qrLocation,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      qrValidationResult: qrValidationResult ?? this.qrValidationResult,
      isValidating: isValidating ?? this.isValidating,
      validationError: validationError ?? this.validationError,
      navigated: navigated ?? this.navigated,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class ScanPulangNotifier extends Notifier<ScanPulangState> {
  @override
  ScanPulangState build() => const ScanPulangState();

  void setCameraInitialized(bool v) =>
      state = state.copyWith(cameraInitialized: v);
  void setLastCode(String? c) => state = state.copyWith(lastCode: c);
  void setCurrentPosition(PositionData? p) =>
      state = state.copyWith(currentPosition: p);
  void setLastCodeWithTimestamp(String? c) => state = state.copyWith(
    lastCode: c,
    lastCodeTimestamp: c == null ? null : DateTime.now().millisecondsSinceEpoch,
  );
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
  void setIsScanning(bool v) => state = state.copyWith(isScanning: v);
  void clear() => state = const ScanPulangState();
}

final scanPulangProvider =
    NotifierProvider<ScanPulangNotifier, ScanPulangState>(
      () => ScanPulangNotifier(),
    );
