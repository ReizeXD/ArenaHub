import '../models/user_record.dart';

/// Acesso ao armazenamento local de usuários.
abstract interface class UserDataSource {
  Future<UserRecord?> findByEmail(String email);

  Future<bool> existsByEmail(String email);

  Future<void> insert(UserRecord record);
}
