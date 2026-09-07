import 'role.dart';

/// Usuário autenticado do sistema.
///
/// A entidade não conhece banco, JSON nem HTTP: a tradução para cada formato
/// mora na camada de dados (SRP). Repare que a senha **não** aparece aqui —
/// hash de senha é detalhe de persistência, não de domínio.
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final Role role;

  /// Primeiro nome, para saudações na interface.
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
