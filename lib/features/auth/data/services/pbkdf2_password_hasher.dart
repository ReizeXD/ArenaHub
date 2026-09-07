import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain/services/password_hasher.dart';

/// Implementação de [PasswordHasher] com PBKDF2-HMAC-SHA256.
///
/// Cada senha recebe um salt aleatório próprio, e o hash carrega os
/// parâmetros usados para gerá-lo — assim é possível aumentar o número de
/// iterações no futuro sem invalidar as senhas já cadastradas.
///
/// Formato: `pbkdf2-sha256$<iteracoes>$<salt-base64>$<hash-base64>`
class Pbkdf2PasswordHasher implements PasswordHasher {
  Pbkdf2PasswordHasher({this.iterations = 12000, Random? random})
      : _random = random ?? Random.secure();

  final int iterations;
  final Random _random;

  static const String _algorithm = 'pbkdf2-sha256';
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  @override
  String hash(String plainPassword) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => _random.nextInt(256)),
    );
    final derived = _deriveKey(plainPassword, salt, iterations);

    return '$_algorithm\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  @override
  bool verify({required String plainPassword, required String hashed}) {
    final parts = hashed.split(r'$');
    if (parts.length != 4 || parts[0] != _algorithm) return false;

    final storedIterations = int.tryParse(parts[1]);
    if (storedIterations == null) return false;

    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }

    final derived = _deriveKey(plainPassword, salt, storedIterations);
    return _constantTimeEquals(derived, expected);
  }

  Uint8List _deriveKey(String password, Uint8List salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(password));

    // Com dkLen igual ao tamanho do SHA-256, o PBKDF2 se resume ao bloco T(1).
    final block = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..[salt.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final result = Uint8List.fromList(u);

    for (var round = 1; round < rounds; round++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var i = 0; i < result.length; i++) {
        result[i] ^= u[i];
      }
    }
    return Uint8List.sublistView(result, 0, _keyLength);
  }

  /// Comparação de tempo constante, para não vazar informação pelo tempo de
  /// resposta.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
