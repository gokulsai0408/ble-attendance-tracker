class AuthSession {
  const AuthSession({
    required this.uid,
    required this.role,
    required this.idToken,
    this.name,
    this.email,
  });

  final String uid;
  final String role;
  final String idToken;
  final String? name;
  final String? email;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      uid: json['uid'] as String,
      role: json['role'] as String? ?? '',
      idToken: json['idToken'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}
