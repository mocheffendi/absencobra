import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SharedPrefsUtil {
  // Load all preferences into a map
  static Future<Map<String, Object?>> loadAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, Object?>{};
    for (final k in keys) {
      map[k] = prefs.get(k);
    }
    return map;
  }

  // Get a specific preference value
  static Future<Object?> getPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  // Set a preference value
  static Future<void> setPref(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      throw ArgumentError('Unsupported value type: ${value.runtimeType}');
    }
  }

  // Remove a specific preference
  static Future<void> removePref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Clear all preferences
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Load User from preferences (stored as JSON string)
  static Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        return User.fromJson(json.decode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Save User to preferences (as JSON string)
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString('user', userJson);
  }

  // Remove User from preferences
  static Future<void> removeUser() async {
    await removePref('user');
  }
}
