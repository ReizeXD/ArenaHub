// ignore_for_file: prefer_initializing_formals
import '../domain/strategies/apple_auth_strategy.dart';
import '../domain/strategies/auth_strategy.dart';
import '../domain/strategies/email_password_auth_strategy.dart';
import '../domain/strategies/google_auth_strategy.dart';
import '../domain/usecases/sign_in.dart';
import '../domain/usecases/sign_in_with_apple.dart';
import '../domain/usecases/sign_in_with_google.dart';

/// Cria as estratégias de login que a interface oferece ao usuário.
class AuthStrategyFactory {
  const AuthStrategyFactory({
    required SignIn signIn,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
  })  : _signIn = signIn,
        _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple;

  final SignIn _signIn;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;

  AuthStrategy emailPassword(String email, String password) =>
      EmailPasswordAuthStrategy(_signIn, email: email, password: password);

  AuthStrategy google() => GoogleAuthStrategy(_signInWithGoogle);

  AuthStrategy apple() => AppleAuthStrategy(_signInWithApple);
}
