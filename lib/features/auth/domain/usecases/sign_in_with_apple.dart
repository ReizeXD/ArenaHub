import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../services/session_storage.dart';

/// Caso de uso: autenticar utilizando conta Apple.
class SignInWithApple {
  const SignInWithApple(this._repository, [this._sessionStorage]);

  final AuthRepository _repository;
  final SessionStorage? _sessionStorage;

  Future<Result<AuthSession>> call() async {
    final result = await _repository.signInWithApple();
    if (result is Ok<AuthSession>) {
      await _sessionStorage?.save(result.value);
    }
    return result;
  }
}
