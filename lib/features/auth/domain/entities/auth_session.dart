import 'user.dart';

/// Sessão ativa: quem está autenticado e por quanto tempo.
///
/// O token é opaco de propósito. Hoje o adaptador local emite um token
/// próprio; amanhã um adaptador HTTP entregaria o JWT de um backend. Nenhuma
/// camada acima precisa saber a diferença.
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
