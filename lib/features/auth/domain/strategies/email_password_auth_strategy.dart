import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../usecases/sign_in.dart';
import 'auth_strategy.dart';

/// Autenticação por e-mail e senha.
final class EmailPasswordAuthStrategy implements AuthStrategy {
  const EmailPasswordAuthStrategy(
    this._signIn, {
    required this.email,
    required this.password,
  });

  final SignIn _signIn;
  final String email;
  final String password;

  @override
  Future<Result<AuthSession>> authenticate() =>
      _signIn(email: email, password: password);
}
