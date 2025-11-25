import '../config/env_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthRepository {
  late final AuthService _service;

  AuthRepository._internal(this._service);

  static final AuthRepository _instance = AuthRepository._internal(
    EnvConfig.useMock ? MockAuthService() : ApiAuthService(ApiClient()),
  );

  factory AuthRepository() => _instance;

  Future<User> signIn({required String email, required String password}) {
    return _service.signIn(email: email, password: password);
  }

  Future<User> signUp({
    required String email,
    required String password,
    String? dob,
  }) {
    return _service.signUp(email: email, password: password, dob: dob);
  }
}
