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
    if (emailResult is Err<Email>) {
      return Err(emailResult.failure);
    }
    final validEmail = (emailResult as Ok<Email>).value;

    final result = await _repository.signIn(
      email: validEmail,
      password: Password.unchecked(password),
    );

    if (result is Ok<AuthSession>) {
      await _sessionStorage.save(result.value);
    }
    return result;
  }
}
