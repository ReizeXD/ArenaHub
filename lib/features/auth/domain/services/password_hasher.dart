/// Port de hashing de senha.
abstract interface class PasswordHasher {
  /// Gera o hash — o formato retornado é opaco e deve embutir o que a
  /// implementação precisar (salt, custo, versão do algoritmo).
  String hash(String plainPassword);

  /// Confere a senha digitada contra um hash gerado por [hash].
  bool verify({required String plainPassword, required String hashed});
}
