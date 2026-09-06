import 'package:arenahub/features/auth/data/services/pbkdf2_password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Poucas iterações para o teste rodar rápido; o app usa o padrão.
  final hasher = Pbkdf2PasswordHasher(iterations: 100);

  test('nunca guarda a senha em texto puro', () {
    final hashed = hasher.hash('arena2026');

    expect(hashed, isNot(contains('arena2026')));
    expect(hashed, startsWith('pbkdf2-sha256\$100\$'));
  });

  test('mesma senha gera hashes diferentes (salt por senha)', () {
    expect(hasher.hash('arena2026'), isNot(hasher.hash('arena2026')));
  });

  test('confere a senha correta', () {
    final hashed = hasher.hash('arena2026');

    expect(hasher.verify(plainPassword: 'arena2026', hashed: hashed), isTrue);
  });

  test('rejeita senha errada', () {
    final hashed = hasher.hash('arena2026');

    expect(hasher.verify(plainPassword: 'arena2027', hashed: hashed), isFalse);
  });

  test('rejeita hash malformado sem estourar exceção', () {
    expect(hasher.verify(plainPassword: 'x', hashed: 'lixo'), isFalse);
    expect(
      hasher.verify(plainPassword: 'x', hashed: 'pbkdf2-sha256\$abc\$@\$@'),
      isFalse,
    );
  });

  test('valida hash gerado com outro número de iterações', () {
    // O custo fica gravado no próprio hash, então aumentar as iterações no
    // futuro não invalida as senhas já cadastradas.
    final antigo = Pbkdf2PasswordHasher(iterations: 50).hash('arena2026');

    expect(
      Pbkdf2PasswordHasher(iterations: 5000)
          .verify(plainPassword: 'arena2026', hashed: antigo),
      isTrue,
    );
  });
}
