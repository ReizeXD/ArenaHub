import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/presentation/states/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  test('começa verificando se há sessão salva', () {
    expect(controllerWith().state, isA<AuthChecking>());
  });

  test('sem sessão salva, termina a verificação em não autenticado', () async {
    final controller = controllerWith();

    await controller.restoreSession();

    expect(controller.state, isA<Unauthenticated>());
  });

  test('restaura a sessão gravada ao abrir o app', () async {
    final storage = InMemorySessionStorage()
      ..seed(FakeAuthRepository.sessionFor('jogador@arenahub.com'));
    final controller = controllerWith(storage: storage);

    await controller.restoreSession();

    expect(controller.state, isA<Authenticated>());
    expect(controller.session?.user.email, 'jogador@arenahub.com');
  });

  test('passa por em-progresso antes de autenticar', () async {
    final controller = controllerWith();
    final observed = <AuthState>[];
    controller.addListener(() => observed.add(controller.state));

    await controller.signIn(
      email: 'jogador@arenahub.com',
      password: 'arena2026',
    );

    expect(observed.first, isA<AuthInProgress>());
    expect(observed.last, isA<Authenticated>());
  });

  test('expõe a falha tipada, não uma string interpretada', () async {
    final controller = controllerWith(
      repository: FakeAuthRepository(
        failure: const InvalidCredentialsFailure(),
      ),
    );

    await controller.signIn(
      email: 'jogador@arenahub.com',
      password: 'senhaerrada1',
    );

    expect(controller.state, isA<AuthFailed>());
    expect(
      (controller.state as AuthFailed).failure,
      isA<InvalidCredentialsFailure>(),
    );
  });

  test('dismissError volta para não autenticado sem apagar a sessão', () async {
    final controller = controllerWith();

    await controller.signIn(email: 'jogador@', password: 'arena2026');
    expect(controller.state, isA<AuthFailed>());

    controller.dismissError();

    expect(controller.state, isA<Unauthenticated>());
  });

  test('sair limpa a sessão e volta para não autenticado', () async {
    final storage = InMemorySessionStorage();
    final controller = controllerWith(storage: storage);

    await controller.signIn(
      email: 'jogador@arenahub.com',
      password: 'arena2026',
    );
    await controller.signOut();

    expect(controller.state, isA<Unauthenticated>());
    expect(await storage.read(), isNull);
    expect(storage.clearCalls, 1);
  });
}
