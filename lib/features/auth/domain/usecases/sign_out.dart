import '../services/session_storage.dart';

/// Caso de uso: sair.
///
/// Depende só de [SessionStorage] — pedir o `AuthRepository` aqui seria
/// carregar uma dependência que este caso de uso não usa (ISP).
class SignOut {
  const SignOut(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<void> call() => _sessionStorage.clear();
}
