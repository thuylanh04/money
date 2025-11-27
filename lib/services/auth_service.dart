import 'dart:async';

import '../config/env_config.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

abstract class AuthService {
  Future<User> signIn({required String email, required String password});
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  });
  
  Future<void> signOut();
  Future<bool> isSignedIn();
}

class MockAuthService implements AuthService {
  @override
  Future<User> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = User(id: '1', name: 'Demo User', email: email);
    await StorageService.saveToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
    await StorageService.saveUid(user.id);
    return user;
  }
  
  @override
  Future<void> signOut() async {
    await StorageService.clearAuthData();
  }
  
  @override
  Future<bool> isSignedIn() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = User(id: '1', name: 'New User', email: email);
    await StorageService.saveToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
    await StorageService.saveUid(user.id);
    return user;
  }
}

class ApiAuthService implements AuthService {
  final ApiClient _client;

  ApiAuthService(this._client);

  @override
  Future<User> signIn({required String email, required String password}) async {
    // POST {apiBaseUrl}/api/v1/authens
    // Backend expects: { "username": "...", "password": "..." }
    // Response shape:
    // { "code": 1000, "result": { "token": "...", "authenticated": true, "idFE": "a@gmail.comThu Nov 27 17:49:54 ICT 2025" } }
    final data = await _client.post('/api/v1/authens', body: {
      'username': email,
      'password': password,
    });

    try {
      final result = data['result'];
      if (result is Map<String, dynamic>) {
        final token = result['token'] as String?;
        final idFE = result['idFE'] as String?;
        
        if (token != null && token.isNotEmpty) {
          EnvConfig.apiAuthHeader = 'Bearer $token';
          await StorageService.saveToken(token);
          
          if (idFE != null && idFE.isNotEmpty) {
            // Extract just the email part from idFE (remove the timestamp)
            final emailMatch = RegExp(r'^[^@]+@[^@]+\.[^@]+').firstMatch(idFE);
            final userEmail = emailMatch?.group(0) ?? email;
            await StorageService.saveUid(userEmail);
            return User(id: idFE, name: email, email: userEmail);
          }
          
          return User(id: 'unknown', name: email, email: email);
        }
      }
    } catch (e) {
      print('Error during sign in: $e');
    }
    throw Exception('Failed to sign in');
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    // POST {apiBaseUrl}/api/v1/users/signup
    // Backend example payload: { "username": "...", "password": "...", "dob": "2008-08-16" }
    // Response shape: { "code": 1000, "result": { "uid": "...", "token": "..." } }
    final data = await _client.post('/api/v1/users/signup', body: {
      'username': email,
      'password': password,
      if (dob != null) 'dob': dob,
    });
    
    try {
      final result = data['result'];
      if (result is Map<String, dynamic>) {
        final token = result['token'] as String?;
        final uid = result['uid'] as String?;
        
        if (token != null && token.isNotEmpty && uid != null && uid.isNotEmpty) {
          EnvConfig.apiAuthHeader = 'Bearer $token';
          await StorageService.saveToken(token);
          await StorageService.saveUid(uid);
          return User(id: uid, name: email, email: email);
        }
      }
    } catch (e) {
      print('Error during sign up: $e');
    }
    throw Exception('Failed to sign up');
  }
  
  @override
  Future<void> signOut() async {
    EnvConfig.apiAuthHeader = '';
    await StorageService.clearAuthData();
  }
  
  @override
  Future<bool> isSignedIn() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      EnvConfig.apiAuthHeader = 'Bearer $token';
      return true;
    }
    return false;
  }
}
