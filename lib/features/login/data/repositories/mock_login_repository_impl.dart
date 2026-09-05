import '../../domain/entities/user.dart';
import '../../domain/repositories/login_repository.dart';
import '../models/user_model.dart';

class MockLoginRepositoryImpl implements ILoginRepository {
  @override
  Future<User> login(String email, String password) async {
    // Simula a latência 
    await Future.delayed(const Duration(milliseconds: 1500));

    // Validação simulada de credenciais de teste
    if (email == 'admin@arenahub.com' && password == '123456') {
      return UserModel(
        id: '1',
        name: 'Administrador ArenaHub',
        email: email,
      );
    } else if (email == 'jogador@arenahub.com' && password == '123456') {
      return UserModel(
        id: '2',
        name: 'Craque da Bola',
        email: email,
      );
    } else {
      throw Exception('E-mail ou senha incorretos.');
    }
  }
}
