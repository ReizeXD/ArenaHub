/// De onde a autenticação vem.
enum AuthMode {
  /// Usuários e sessão no próprio aparelho (SQLite + PBKDF2). Roda sem
  /// internet e sem configuração.
  local,

  /// Firebase Authentication para a credencial, Firestore para nome e papel.
  /// Exige `flutterfire configure` e conexão.
  firebase,
}
