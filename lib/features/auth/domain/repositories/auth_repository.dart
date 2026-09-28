import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../entities/sign_up_data.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

/// Port de saída da autenticação.
abstract interface class AuthRepository {
  /// Autentica e devolve a sessão correspondente.
  Future<Result<AuthSession>> signIn({
    required Email email,
    required Password password,
  });

  /// Cria a conta e já devolve a sessão do usuário recém-criado.
  Future<Result<AuthSession>> signUp(SignUpData data);
}
