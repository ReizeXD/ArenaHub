import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../services/session_storage.dart';

/// Caso de uso: autenticar utilizando conta Google.
class SignInWithGoogle {
  const SignInWithGoogle(this._repository, [this._sessionStorage]);

  final AuthRepository _repository;
  final SessionStorage? _sessionStorage;

  Future<Result<AuthSession>> call() async {
    final result = await _repository.signInWithGoogle();
    if (result case Ok<AuthSession> success) {
      await _sessionStorage?.save(success.value);
    }
    return result;
  }
}
