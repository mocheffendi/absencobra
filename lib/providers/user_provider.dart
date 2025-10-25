import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:absencobra/user.dart';

class UserNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) => state = user;
  void clearUser() => state = null;
}

final userProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);
