import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../entities/auth_session.dart';
import '../entities/role.dart';
import '../entities/sign_up_data.dart';
import '../repositories/auth_repository.dart';
import '../services/session_storage.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

/// Caso de uso: criar conta.
class SignUp {
  const SignUp(this._repository, this._sessionStorage);

  final AuthRepository _repository;
  final SessionStorage _sessionStorage;

  Future<Result<AuthSession>> call({
    required String fullName,
    required String email,
    required String password,
    required Role role,
  }) async {
    if (fullName.trim().split(RegExp(r'\s+')).length < 2) {
      return const Err(InvalidNameFailure());
    }

    final emailResult = Email.create(email);
    if (emailResult is Err<Email>) {
      return Err(emailResult.failure);
    }

    final passwordResult = Password.create(password);
    if (passwordResult is Err<Password>) {
      return Err(passwordResult.failure);
    }

    final result = await _repository.signUp(
      SignUpData(
        fullName: fullName.trim(),
        email: (emailResult as Ok<Email>).value,
        password: (passwordResult as Ok<Password>).value,
        role: role,
      ),
    );

    if (result is Ok<AuthSession>) {
      await _sessionStorage.save(result.value);
    }
    return result;
  }
}
