import 'package:arenahub/features/auth/data/mappers/session_json_mapper.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  const mapper = SessionJsonMapper();

  test('ida e volta preserva usuário e papel', () {
    final session = FakeAuthRepository.sessionFor(
      'dono@arenahub.com',
      fullName: 'Ana Ribeiro',
      role: Role.owner,
    );

    final restored = mapper.decode(mapper.encode(session))!;

    expect(restored.user.email, 'dono@arenahub.com');
    expect(restored.user.fullName, 'Ana Ribeiro');
    expect(restored.user.role, Role.owner);
    expect(restored.token, session.token);
  });

  test('devolve null para conteúdo ilegível em vez de estourar', () {
    // Dado gravado por uma versão antiga do app não pode derrubar a abertura.
    expect(mapper.decode('não é json'), isNull);
    expect(mapper.decode('{"token":"x"}'), isNull);
  });
}
