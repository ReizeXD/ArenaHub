import '../../../../core/failure.dart';
import '../../domain/entities/auth_session.dart';

/// Estados possíveis da autenticação.
///
/// Tipo selado: o `switch` na interface é exaustivo, e acrescentar um estado
/// novo vira erro de compilação em quem esqueceu de tratá-lo.
sealed class AuthState {
  const AuthState();
}

/// Ainda verificando se existe sessão salva.
final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Requisição em andamento — a UI usa isto para travar o botão.
final class AuthInProgress extends AuthState {
  const AuthInProgress();
}

final class Authenticated extends AuthState {
  const Authenticated(this.session);

  final AuthSession session;
}

final class AuthFailed extends AuthState {
  const AuthFailed(this.failure);

  final Failure failure;
}
