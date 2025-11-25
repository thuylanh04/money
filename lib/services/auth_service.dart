import 'dart:async';

import '../models/user.dart';
import '../services/api_client.dart';

abstract class AuthService {
  Future<User> signIn({required String email, required String password});
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  });
}

class MockAuthService implements AuthService {
  @override
  Future<User> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return User(id: '1', name: 'Demo User', email: email);
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return User(id: '1', name: 'New User', email: email);
  }
}

class ApiAuthService implements AuthService {
  final ApiClient _client;

  ApiAuthService(this._client);

  @override
  Future<User> signIn({required String email, required String password}) async {
    // POST {apiBaseUrl}/authen
    // Backend expects: { "username": "...", "password": "..." }
    // Similar to signUp, we only care that the call succeeds (2xx).
    await _client.post('/authen', body: {
      'username': email,
      'password': password,
    });
    return User(id: 'signin', name: email, email: email);
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    // POST {apiBaseUrl}/api/v1/users/signup
    // Backend example payload: { "username": "...", "password": "...", "dob": "2008-08-16" }
    // We only care that the request succeeds (2xx). The body shape may vary,
    // so we don't rely on a specific 'user' field here.
    await _client.post('/api/v1/users/signup', body: {
      'username': email,
      'password': password,
      if (dob != null) 'dob': dob,
    });
    return User(id: 'signup', name: email, email: email);
  }
}
