import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../services/session_storage.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

/// Caso de uso: entrar no sistema.
class SignIn {
  const SignIn(this._repository, this._sessionStorage);

  final AuthRepository _repository;
  final SessionStorage _sessionStorage;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    final emailResult = Email.create(email);
    if (emailResult case Err<Email> error) return error.cast();

    final result = await _repository.signIn(
      email: (emailResult as Ok<Email>).value,
      password: Password.unchecked(password),
    );

    if (result case Ok<AuthSession> success) {
      await _sessionStorage.save(success.value);
    }
    return result;
  }
}
