import '../entities/auth_session.dart';

/// Port de persistência da sessão ativa.
abstract interface class SessionStorage {
  Future<AuthSession?> read();

  Future<void> save(AuthSession session);

  Future<void> clear();
}
