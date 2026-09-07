import '../value_objects/email.dart';
import '../value_objects/password.dart';
import 'role.dart';

/// Dados já validados para criar uma conta.
///
/// Só é possível construir esta classe a partir de value objects válidos,
/// então nenhum adaptador precisa revalidar e-mail ou senha.
class SignUpData {
  const SignUpData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final Email email;
  final Password password;
  final Role role;
}
