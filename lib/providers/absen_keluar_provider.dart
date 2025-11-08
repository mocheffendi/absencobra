import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbsenKeluarState {
  final bool isSending;
  final String? message;
  final bool? success;

  const AbsenKeluarState({this.isSending = false, this.message, this.success});

  AbsenKeluarState copyWith({bool? isSending, String? message, bool? success}) {
    return AbsenKeluarState(
      isSending: isSending ?? this.isSending,
      message: message ?? this.message,
      success: success ?? this.success,
    );
  }
}

class AbsenKeluarNotifier extends Notifier<AbsenKeluarState> {
  @override
  AbsenKeluarState build() => const AbsenKeluarState();

  void setSending(bool sending) {
    state = state.copyWith(isSending: sending);
  }

  void setMessage(String message, {bool? success}) {
    state = state.copyWith(message: message, success: success);
  }

  void reset() {
    state = const AbsenKeluarState();
  }
}

final absenKeluarProvider =
    NotifierProvider<AbsenKeluarNotifier, AbsenKeluarState>(() {
      return AbsenKeluarNotifier();
    });
