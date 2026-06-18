import 'package:flutter/foundation.dart';

import '../features/auth/data/auth_models.dart';
import '../features/auth/data/auth_session_store.dart';

class UserSessionProvider extends ChangeNotifier {
  UserSessionProvider(
      {AuthSessionStore sessionStore = const AuthSessionStore()})
      : _sessionStore = sessionStore;

  final AuthSessionStore _sessionStore;
  KomiUser? _user;

  KomiUser? get user => _user;

  Future<void> load() async {
    final user = await _sessionStore.readUser();
    _user = user;
    notifyListeners();
  }

  Future<void> setUser(KomiUser user) async {
    _user = user;
    await _sessionStore.updateUser(user);
    notifyListeners();
  }

  Future<void> clear() async {
    await _sessionStore.clear();
    _user = null;
    notifyListeners();
  }
}
