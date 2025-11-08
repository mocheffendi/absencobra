import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// settings import removed: avatar URL is now fixed to panelcobra assets path

// Downloads [avatarPathOrUrl] (if it's a URL or relative path) and saves it
// under application documents/avatars/avatar_<userId>.jpg. Returns the local
// file path when successful, otherwise null.
Future<String?> downloadAndSaveAvatar(
  String? avatarPathOrUrl,
  int userId,
) async {
  if (avatarPathOrUrl == null || avatarPathOrUrl.isEmpty) return null;

  // Always build avatar URL from the panelcobra assets path.
  // The API stores only the filename in `user.avatar`, so we construct
  // the full URL here regardless of incoming value.
  final avatarBase = 'https://panelcobra.cbsguard.co.id/assets/img/avatar';
  final trimmed = avatarPathOrUrl.replaceFirst(RegExp(r'^/+'), '');
  final imageUrl = '$avatarBase/$trimmed';

  try {
    final resp = await http.get(Uri.parse(imageUrl));
    if (resp.statusCode == 200) {
      final bytes = resp.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${dir.path}/avatars');
      if (!await avatarsDir.exists()) await avatarsDir.create(recursive: true);
      final file = File('${avatarsDir.path}/avatar_$userId.jpg');
      await file.writeAsBytes(bytes, flush: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar_lokal', file.path);
      await prefs.setString('avatar', imageUrl);

      // Also update the stored `user` JSON (if present) so the User model's
      // `avatar_lokal` field stays in sync with the top-level prefs key.
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final decoded = json.decode(userJson);
          if (decoded is Map<String, dynamic>) {
            decoded['avatar_lokal'] = file.path;
            await prefs.setString('user', json.encode(decoded));
          }
        } catch (_) {
          // ignore malformed user JSON
        }
      }
      return file.path;
    }
  } catch (_) {
    // ignore
  }
  return null;
}
