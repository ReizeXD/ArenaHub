import '../models/user_record.dart';

/// Acesso ao armazenamento local de usuários.
///
/// É um detalhe do adaptador local — por isso vive na camada de dados, e não
/// no domínio.
abstract interface class UserDataSource {
  Future<UserRecord?> findByEmail(String email);

  Future<bool> existsByEmail(String email);

  Future<void> insert(UserRecord record);
}
