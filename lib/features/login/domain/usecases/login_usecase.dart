import '../entities/user.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  final ILoginRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(String email, String password) async {
    // validações
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('E-mail inválido.');
    }
    if (password.length < 6) {
      throw Exception('A senha deve ter pelo menos 6 caracteres.');
    }

    // O caso de uso orquestra a chamada ao repositório
    return await repository.login(email, password);
  }
}
