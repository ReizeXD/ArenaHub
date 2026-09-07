import 'package:arenahub/features/auth/domain/usecases/get_current_session.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  late InMemorySessionStorage sessionStorage;

  setUp(() => sessionStorage = InMemorySessionStorage());

  test('restaura a sessão salva ao reabrir o app', () async {
    sessionStorage.seed(FakeAuthRepository.sessionFor('jogador@arenahub.com'));

    final session = await GetCurrentSession(sessionStorage)();

    expect(session?.user.email, 'jogador@arenahub.com');
  });

  test('descarta e limpa sessão expirada', () async {
    sessionStorage.seed(
      FakeAuthRepository.sessionFor(
        'jogador@arenahub.com',
        validFor: const Duration(days: -1),
      ),
    );

    final session = await GetCurrentSession(sessionStorage)();

    expect(session, isNull);
    expect(sessionStorage.clearCalls, 1);
  });

  test('sair apaga a sessão do dispositivo', () async {
    sessionStorage.seed(FakeAuthRepository.sessionFor('jogador@arenahub.com'));

    await SignOut(sessionStorage)();

    expect(await sessionStorage.read(), isNull);
  });
}
