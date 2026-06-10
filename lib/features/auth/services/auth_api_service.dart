import '../models/auth_session.dart';
import 'auth_state.dart';

class AuthApiService {
  // Use mock logic by default so the app works without a backend
  final bool _useMock = true;

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

    throw UnimplementedError("Backend not connected");
  }
}
