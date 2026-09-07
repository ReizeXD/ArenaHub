import '../entities/auth_session.dart';
import '../services/session_storage.dart';

/// Caso de uso: recuperar a sessão salva ao abrir o app.
///
/// Sessão expirada é descartada aqui, para que nenhuma tela precise repetir
/// essa checagem.
class GetCurrentSession {
  const GetCurrentSession(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<AuthSession?> call() async {
    final session = await _sessionStorage.read();
    if (session == null) return null;

    if (session.isExpired) {
      await _sessionStorage.clear();
      return null;
    }
    return session;
  }
}
