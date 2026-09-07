import '../../domain/entities/role.dart';
import '../../domain/entities/user.dart';

/// Como um usuário é guardado localmente: a entidade de domínio mais o hash
/// da senha, que é assunto exclusivo da persistência.
///
/// Repare que este modelo **compõe** a entidade em vez de herdar dela: o
/// domínio não ganha campos de banco por tabela de dentro.
class UserRecord {
  const UserRecord({required this.user, required this.passwordHash});

  final User user;
  final String passwordHash;

  Map<String, Object?> toRow() => <String, Object?>{
        'id': user.id,
        'full_name': user.fullName,
        'email': user.email,
        'role': user.role.wire,
        'password_hash': passwordHash,
      };

  static UserRecord fromRow(Map<String, Object?> row) => UserRecord(
        user: User(
          id: row['id']! as String,
          fullName: row['full_name']! as String,
          email: row['email']! as String,
          role: Role.fromWire(row['role']! as String),
        ),
        passwordHash: row['password_hash']! as String,
      );
}
