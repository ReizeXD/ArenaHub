/// De onde a autenticação vem.
///
/// As duas opções implementam o mesmo `AuthRepository`, então trocar de uma
/// para a outra não muda nenhuma regra de negócio nem nenhuma tela.
enum AuthMode {
  /// Usuários e sessão no próprio aparelho (SQLite + PBKDF2). Roda sem
  /// internet e sem configuração.
  local,

  /// Firebase Authentication para a credencial, Firestore para nome e papel.
  /// Exige `flutterfire configure` e conexão.
  firebase,
}
