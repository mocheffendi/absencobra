import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobra_apps/models/user.dart';
import 'package:flutter_riverpod/legacy.dart';

class UserNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) => state = user;
  void clearUser() => state = null;
}

final userProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);

final prefsProvider = StateProvider<Map<String, Object?>>((ref) => {});
final userPrefsProvider = StateProvider<User?>((ref) => null);
