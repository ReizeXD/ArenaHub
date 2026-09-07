import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../entities/sign_up_data.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

/// Port de saída da autenticação.
///
/// Peça central do Princípio da Inversão de Dependência: os casos de uso
/// dependem desta abstração, nunca de SQLite ou HTTP. Trocar a origem dos
/// dados (local ↔ backend) é acrescentar uma implementação, não editar as
/// existentes — Aberto/Fechado na prática.
abstract interface class AuthRepository {
  /// Autentica e devolve a sessão correspondente.
  Future<Result<AuthSession>> signIn({
    required Email email,
    required Password password,
  });

  /// Cria a conta e já devolve a sessão do usuário recém-criado.
  Future<Result<AuthSession>> signUp(SignUpData data);
}
