import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/value_objects/email.dart';
import 'package:arenahub/features/auth/domain/value_objects/password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email', () {
    test('normaliza espaços e maiúsculas', () {
      final result = Email.create('  Jogador@ArenaHub.COM  ');

      expect(result, isA<Ok<Email>>());
      expect((result as Ok<Email>).value.value, 'jogador@arenahub.com');
    });

    test('recusa endereço sem domínio', () {
      final result = Email.create('jogador@');

      expect((result as Err<Email>).failure, isA<InvalidEmailFailure>());
    });
  });

  group('Password', () {
    test('aceita senha com letra e número', () {
      expect(Password.create('arena2026'), isA<Ok<Password>>());
    });

    test('recusa senha curta', () {
      expect(Password.create('abc123'), isA<Err<Password>>());
    });

    test('recusa senha só de números', () {
      expect(Password.create('123456789'), isA<Err<Password>>());
    });

    test('não expõe o valor ao ser convertida em texto', () {
      expect(Password.unchecked('arena2026').toString(), isNot(contains('arena')));
    });
  });

  group('Role', () {
    test('traduz o valor persistido de volta para o enum', () {
      expect(Role.fromWire('OWNER'), Role.owner);
      expect(Role.fromWire('admin'), Role.admin);
    });

    test('cai em jogador diante de um papel desconhecido', () {
      // Menor privilégio: um dado corrompido não deve virar administrador.
      expect(Role.fromWire('SUPERUSER'), Role.player);
    });
  });
}
