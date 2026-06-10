import '../models/auth_session.dart';

class AuthState {
  AuthState._();

  static final AuthState instance = AuthState._();

  AuthSession? currentSession;

  bool get isLoggedIn => currentSession != null;
  String? get token => currentSession?.idToken;
  String? get uid => currentSession?.uid;
}
