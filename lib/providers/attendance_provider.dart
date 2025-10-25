import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier that holds the current id_absen (masuk) so other pages (pulang)
// can access it in-memory without hitting SharedPreferences.
class IdAbsenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setId(String? id) => state = id;
  void clear() => state = null;
}

final idAbsenProvider = NotifierProvider<IdAbsenNotifier, String?>(() {
  return IdAbsenNotifier();
});
