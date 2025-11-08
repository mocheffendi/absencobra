import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      String? avatarUrl = prefs.getString('avatar');

      // Fallback: if there's no top-level 'avatar' key, try to read it from
      // the stored user JSON (prefs['user']) which may contain the avatar field.
      if ((avatarUrl == null || avatarUrl.isEmpty) &&
          prefs.containsKey('user')) {
        try {
          final userJson = prefs.getString('user');
          if (userJson != null && userJson.isNotEmpty) {
            final Map<String, dynamic> data = json.decode(userJson);
            final possible = data['avatar'] as String?;
            if (possible != null && possible.isNotEmpty) {
              avatarUrl = possible;
            }
          }
        } catch (_) {
          // ignore parse errors
        }
      }
      // If the stored avatar is just a filename (no http scheme), build
      // the full panelcobra URL so NetworkImage can load it.
      if (avatarUrl != null &&
          avatarUrl.isNotEmpty &&
          !avatarUrl.startsWith('http')) {
        final base = 'https://panelcobra.cbsguard.co.id/assets/img/avatar';
        final trimmed = avatarUrl.replaceFirst(RegExp(r'^/+'), '');
        avatarUrl = '$base/$trimmed';
      }

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
