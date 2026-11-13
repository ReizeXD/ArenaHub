import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../usecases/sign_in_with_apple.dart';
import 'auth_strategy.dart';

/// Autenticação pela conta Apple.
final class AppleAuthStrategy implements AuthStrategy {
  const AppleAuthStrategy(this._signInWithApple);

  final SignInWithApple _signInWithApple;

  @override
  Future<Result<AuthSession>> authenticate() => _signInWithApple();
}
