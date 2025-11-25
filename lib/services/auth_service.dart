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
    // POST https://a63f923336f4.ngrok-free.app/authen
    final json = await _client.post('/authen', body: {
      'email': email,
      'password': password,
    });
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    // POST https://a63f923336f4.ngrok-free.app/api/v1/users/signup
    final json = await _client.post('/api/v1/users/signup', body: {
      'email': email,
      'password': password,
      if (dob != null) 'dob': dob,
    });
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }
}
