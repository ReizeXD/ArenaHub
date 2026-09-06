import 'dart:convert';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/user.dart';

/// Traduz [AuthSession] de/para JSON.
///
/// A tradução mora aqui, e não na entidade: mudar o formato de
/// armazenamento não deve ser motivo para mexer no domínio (SRP).
class SessionJsonMapper {
  const SessionJsonMapper();

  String encode(AuthSession session) => jsonEncode(<String, Object?>{
        'token': session.token,
        'issued_at': session.issuedAt.toIso8601String(),
        'expires_at': session.expiresAt.toIso8601String(),
        'user': <String, Object?>{
          'id': session.user.id,
          'full_name': session.user.fullName,
          'email': session.user.email,
          'role': session.user.role.wire,
        },
      });

  /// Devolve `null` quando o conteúdo salvo é ilegível (versão antiga do app,
  /// dado corrompido), para o chamador tratar como "sem sessão".
  AuthSession? decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final user = json['user']! as Map<String, Object?>;

      return AuthSession(
        token: json['token']! as String,
        issuedAt: DateTime.parse(json['issued_at']! as String),
        expiresAt: DateTime.parse(json['expires_at']! as String),
        user: User(
          id: user['id']! as String,
          fullName: user['full_name']! as String,
          email: user['email']! as String,
          role: Role.fromWire(user['role']! as String),
        ),
      );
    } on Object {
      return null;
    }
  }
}
