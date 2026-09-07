import '../models/user_record.dart';
import 'user_data_source.dart';

/// [UserDataSource] em memória.
///
/// Segunda implementação do mesmo port: atende a web (onde o SQLite nativo
/// não existe) e os testes, sem que nenhuma linha do domínio mude. É o
/// Aberto/Fechado visível — estender o sistema foi acrescentar uma classe.
class InMemoryUserDataSource implements UserDataSource {
  final Map<String, UserRecord> _byEmail = <String, UserRecord>{};

  @override
  Future<UserRecord?> findByEmail(String email) async => _byEmail[email];

  @override
  Future<bool> existsByEmail(String email) async => _byEmail.containsKey(email);

  @override
  Future<void> insert(UserRecord record) async {
    _byEmail[record.user.email] = record;
  }
}
