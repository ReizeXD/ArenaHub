import '../../domain/entities/role.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/password_hasher.dart';
import '../datasources/user_data_source.dart';
import '../models/user_record.dart';

/// Contas de demonstração, criadas na primeira execução.
///
/// Existem porque a tela de cadastro ainda não foi feita; quando ela chegar,
/// basta parar de chamar o seeder. As senhas são gravadas com o mesmo hasher
/// da aplicação — não há senha em texto puro em lugar nenhum do projeto.
class DemoUserSeeder {
  const DemoUserSeeder(this._dataSource, this._passwordHasher);

  final UserDataSource _dataSource;
  final PasswordHasher _passwordHasher;

  /// Senha única para as três contas, dentro da política do `Password`
  /// (mínimo de 8 caracteres, com letra e número).
  static const String demoPassword = 'arena2026';

  static const List<({String id, String name, String email, Role role})>
      demoUsers = [
    (
      id: 'demo-admin',
      name: 'Administrador ArenaHub',
      email: 'admin@arenahub.com',
      role: Role.admin,
    ),
    (
      id: 'demo-owner',
      name: 'Ana Ribeiro',
      email: 'dono@arenahub.com',
      role: Role.owner,
    ),
    (
      id: 'demo-player',
      name: 'Craque da Bola',
      email: 'jogador@arenahub.com',
      role: Role.player,
    ),
  ];

  Future<void> seed() async {
    for (final demo in demoUsers) {
      if (await _dataSource.existsByEmail(demo.email)) continue;

      await _dataSource.insert(
        UserRecord(
          user: User(
            id: demo.id,
            fullName: demo.name,
            email: demo.email,
            role: demo.role,
          ),
          passwordHash: _passwordHasher.hash(demoPassword),
        ),
      );
    }
  }
}
