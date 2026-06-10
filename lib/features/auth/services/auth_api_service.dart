import '../../../core/network/api_client.dart';
import '../models/auth_session.dart';
import 'auth_state.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  // Set this to false to use the real backend
  static const bool _useMock = false;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _apiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final session = AuthSession(
        idToken: 'mock_token',
        uid: 'STUDENT_GOKUL',
        name: 'Gokul',
        email: email,
        role: 'student',
      );
      AuthState.instance.currentSession = session;
      return session;
    }

    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final session = AuthSession.fromJson(response);
    AuthState.instance.currentSession = session;
    return session;
  }
}
