import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbsenMasukState {
  final bool isSending;
  final String? message;
  final bool? success;

  const AbsenMasukState({this.isSending = false, this.message, this.success});

  AbsenMasukState copyWith({bool? isSending, String? message, bool? success}) {
    return AbsenMasukState(
      isSending: isSending ?? this.isSending,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class AbsenMasukNotifier extends Notifier<AbsenMasukState> {
  @override
  AbsenMasukState build() => const AbsenMasukState();

  void setSending(bool sending) {
    state = state.copyWith(isSending: sending);
  }

  void setMessage(String message, {bool? success}) {
    state = state.copyWith(message: message, success: success);
  }

  void reset() {
    state = const AbsenMasukState();
  }
}

final absenMasukProvider =
    NotifierProvider<AbsenMasukNotifier, AbsenMasukState>(() {
      return AbsenMasukNotifier();
    });
