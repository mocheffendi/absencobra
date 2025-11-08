import 'package:flutter_riverpod/flutter_riverpod.dart';

class FaceApiState {
  final bool isUploading;
  final String? message;
  final double? percent;
  final bool? success;

  const FaceApiState({
    this.isUploading = false,
    this.message,
    this.percent,
    this.success,
  });

  FaceApiState copyWith({
    bool? isUploading,
    String? message,
    double? percent,
    bool? success,
  }) {
    return FaceApiState(
      isUploading: isUploading ?? this.isUploading,
      message: message ?? this.message,
      percent: percent ?? this.percent,
      success: success ?? this.success,
    );
  }
}

class FaceApiNotifier extends Notifier<FaceApiState> {
  @override
  FaceApiState build() => const FaceApiState();

  void setUploading(bool uploading) {
    state = state.copyWith(isUploading: uploading);
  }

  void setResult(String message, {double? percent, bool? success}) {
    state = state.copyWith(
      message: message,
      percent: percent,
      success: success,
      isUploading: false,
    );
  }

  void reset() {
    state = const FaceApiState();
  }
}

final faceApiProvider = NotifierProvider<FaceApiNotifier, FaceApiState>(() {
  return FaceApiNotifier();
});
