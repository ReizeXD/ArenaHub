import 'role.dart';

/// Usuário autenticado do sistema.
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
