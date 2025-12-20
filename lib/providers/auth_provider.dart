import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env_config.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  final SharedPreferences _prefs;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider(this._prefs) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userJson = _prefs.getString('current_user');
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
        if (_currentUser?.token != null && _currentUser!.token!.isNotEmpty) {
          EnvConfig.apiAuthHeader = 'Bearer ${_currentUser!.token!}';
          // If email is not in user object but exists in storage, update it
          if ((_currentUser?.email == null || _currentUser!.email!.isEmpty)) {
            final savedEmail = await StorageService.getEmail();
            if (savedEmail != null && savedEmail.isNotEmpty) {
              _currentUser = _currentUser!.copyWith(email: savedEmail);
              _prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
            }
          }
        }
      } catch (e) {
        print('Error loading user: $e');
        _currentUser = null;
      }
      notifyListeners();
    } else {
      // Try to load just the email if no user is logged in
      final savedEmail = await StorageService.getEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _currentUser = User(id: 'temp', email: savedEmail);
        notifyListeners();
      }
    }
  }

  void setUser(User user) {
    _currentUser = user;
    _prefs.setString('current_user', jsonEncode(user.toJson()));
    if (user.token != null && user.token!.isNotEmpty) {
      EnvConfig.apiAuthHeader = 'Bearer ${user.token!}';
      // Save email to storage when user is set
      if (user.email != null && user.email!.isNotEmpty) {
        StorageService.saveEmail(user.email!);
      }
    }
    notifyListeners();
  }

  Future<void> clearUser() async {
    _currentUser = null;
    // Clear all authentication related data
    await _prefs.remove('current_user');
    await _prefs.clear(); // Clear all stored preferences
    await StorageService.clearAuthData();
    EnvConfig.apiAuthHeader = '';
    // Clear any other authentication related data if needed
    try {
      final authRepo = AuthRepository();
      await authRepo.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
    notifyListeners();
  }
}
