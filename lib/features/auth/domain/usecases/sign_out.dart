import '../services/session_storage.dart';

/// Caso de uso: sair.
class SignOut {
  const SignOut(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<void> call() => _sessionStorage.clear();
}
