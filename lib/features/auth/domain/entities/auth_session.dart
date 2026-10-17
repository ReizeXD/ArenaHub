import 'user.dart';

/// Sessão ativa: quem está autenticado e por quanto tempo.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
  });

  final User user;
  final String token;
  final DateTime issuedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
