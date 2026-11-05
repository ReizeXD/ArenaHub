import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../usecases/sign_in_with_google.dart';
import 'auth_strategy.dart';

/// Autenticação pela conta Google.
final class GoogleAuthStrategy implements AuthStrategy {
  const GoogleAuthStrategy(this._signInWithGoogle);

  final SignInWithGoogle _signInWithGoogle;

  @override
  Future<Result<AuthSession>> authenticate() => _signInWithGoogle();
}
