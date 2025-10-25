import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarData {
  final String? avatarLocalPath;
  final String? avatarUrlFromPrefs;

  const AvatarData({this.avatarLocalPath, this.avatarUrlFromPrefs});

  AvatarData copyWith({String? avatarLocalPath, String? avatarUrlFromPrefs}) {
    return AvatarData(
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      avatarUrlFromPrefs: avatarUrlFromPrefs ?? this.avatarUrlFromPrefs,
    );
  }
}

class AvatarNotifier extends Notifier<AvatarData> {
  @override
  AvatarData build() => const AvatarData();

  Future<void> loadAvatarFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarLocal = prefs.getString('avatar_lokal');
      final avatarUrl = prefs.getString('avatar');
      state = state.copyWith(
        avatarLocalPath: avatarLocal,
        avatarUrlFromPrefs: avatarUrl,
      );
    } catch (_) {
      // Ignore errors
    }
  }
}

final avatarProvider = NotifierProvider<AvatarNotifier, AvatarData>(() {
  return AvatarNotifier();
});
