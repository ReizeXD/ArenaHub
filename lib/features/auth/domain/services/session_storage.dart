import '../entities/auth_session.dart';

/// Port de persistência da sessão ativa.
///
/// Separado de `AuthRepository` porque são responsabilidades distintas:
/// autenticar credenciais e lembrar quem está logado mudam por motivos
/// diferentes (SRP).
abstract interface class SessionStorage {
  Future<AuthSession?> read();

  Future<void> save(AuthSession session);

  Future<void> clear();
}
