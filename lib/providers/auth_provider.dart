import 'package:flutter/material.dart';
import 'package:money_manage/config/env_config.dart';
import 'package:money_manage/models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  void setUser(User user) {
    _currentUser = user;
    if (user.token != null && user.token!.isNotEmpty) {
      EnvConfig.apiAuthHeader = 'Bearer ${user.token!}';
    }
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    EnvConfig.apiAuthHeader = '';
    notifyListeners();
  }
}
