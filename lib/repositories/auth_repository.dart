import 'dart:convert';
import '../config/env_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthRepository {
  late final AuthService _service;
  User? _currentUser;

  AuthRepository._internal(this._service);

  static final AuthRepository _instance = AuthRepository._internal(
    EnvConfig.useMock ? MockAuthService() : ApiAuthService(ApiClient()),
  );

  factory AuthRepository() => _instance;

  User? get currentUser => _currentUser;

  Future<User> login(String email, String password) async {
    return await signIn(email: email, password: password);
  }

  Future<User> signIn({required String email, required String password}) async {
    final user = await _service.signIn(email: email, password: password);
    _currentUser = user;
    return user;
  }

  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) async {
    final user = await _service.signUp(email: email, password: password, dob: dob);
    _currentUser = user;
    return user;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _currentUser = null;
  }
}
