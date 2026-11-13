import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/strategies/auth_strategy.dart';
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
    final strategies = strategiesWith();
    final observed = <AuthState>[];
    controller.addListener(() => observed.add(controller.state));

    await controller.signInWith(strategies.emailPassword('jogador@arenahub.com', 'arena2026'));

    expect(observed.first, isA<AuthInProgress>());
    expect(observed.last, isA<Authenticated>());
  });

  test('expõe a falha tipada, não uma string interpretada', () async {
    final repository = FakeAuthRepository(failure: const InvalidCredentialsFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);

    await controller.signInWith(strategies.emailPassword('jogador@arenahub.com', 'senhaerrada1'));

    expect(controller.state, isA<AuthFailed>());
    expect(
      (controller.state as AuthFailed).failure,
      isA<InvalidCredentialsFailure>(),
    );
  });

  test('dismissError volta para não autenticado sem apagar a sessão', () async {
    final controller = controllerWith();
    final strategies = strategiesWith();

    await controller.signInWith(strategies.emailPassword('jogador@', 'arena2026'));
    expect(controller.state, isA<AuthFailed>());

    controller.dismissError();

    expect(controller.state, isA<Unauthenticated>());
  });

  test('sair limpa a sessão e volta para não autenticado', () async {
    final storage = InMemorySessionStorage();
    final controller = controllerWith(storage: storage);
    final strategies = strategiesWith(storage: storage);

    await controller.signInWith(strategies.emailPassword('jogador@arenahub.com', 'arena2026'));
    await controller.signOut();

    expect(controller.state, isA<Unauthenticated>());
    expect(await storage.read(), isNull);
    expect(storage.clearCalls, 1);
  });

  group('Login social com Google', () {
    test('autentica com sucesso e passa por em-progresso', () async {
      final controller = controllerWith();
      final strategies = strategiesWith();
      final observed = <AuthState>[];
      controller.addListener(() => observed.add(controller.state));

      await controller.signInWith(strategies.google());

      expect(observed.first, isA<AuthInProgress>());
      expect(observed.last, isA<Authenticated>());
      expect(controller.session?.user.email, 'atleta.google@arenahub.com');
    });

    test('quando cancelado pelo usuário, volta para não autenticado sem erro', () async {
      final repository = FakeAuthRepository(failure: const OAuthCancelledFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);
      final observed = <AuthState>[];
      controller.addListener(() => observed.add(controller.state));

      await controller.signInWith(strategies.google());

      expect(observed.first, isA<AuthInProgress>());
      expect(observed.last, isA<Unauthenticated>());
      expect(controller.state, isA<Unauthenticated>());
    });

    test('quando ocorre colisão de conta, expõe AuthFailed tipado', () async {
      final repository = FakeAuthRepository(failure: const OAuthAccountCollisionFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);

      await controller.signInWith(strategies.google());

      expect(controller.state, isA<AuthFailed>());
      expect(
        (controller.state as AuthFailed).failure,
        isA<OAuthAccountCollisionFailure>(),
      );
    });

    test('quando ocorre erro de rede, expõe AuthFailed tipado', () async {
      final repository = FakeAuthRepository(failure: const OAuthNetworkFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);

      await controller.signInWith(strategies.google());

      expect(controller.state, isA<AuthFailed>());
      expect(
        (controller.state as AuthFailed).failure,
        isA<OAuthNetworkFailure>(),
      );
    });
  });

  group('Login social com Apple', () {
    test('autentica com sucesso e passa por em-progresso', () async {
      final controller = controllerWith();
      final strategies = strategiesWith();
      final observed = <AuthState>[];
      controller.addListener(() => observed.add(controller.state));

      await controller.signInWith(strategies.apple());

      expect(observed.first, isA<AuthInProgress>());
      expect(observed.last, isA<Authenticated>());
      expect(controller.session?.user.email, 'atleta.apple@arenahub.com');
    });

    test('quando cancelado pelo usuário, volta para não autenticado sem erro', () async {
      final repository = FakeAuthRepository(failure: const OAuthCancelledFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);
      final observed = <AuthState>[];
      controller.addListener(() => observed.add(controller.state));

      await controller.signInWith(strategies.apple());

      expect(observed.first, isA<AuthInProgress>());
      expect(observed.last, isA<Unauthenticated>());
      expect(controller.state, isA<Unauthenticated>());
    });

    test('quando ocorre colisão de conta, expõe AuthFailed tipado', () async {
      final repository = FakeAuthRepository(failure: const OAuthAccountCollisionFailure());
    final controller = controllerWith(repository: repository);
    final strategies = strategiesWith(repository: repository);

      await controller.signInWith(strategies.apple());

      expect(controller.state, isA<AuthFailed>());
      expect(
        (controller.state as AuthFailed).failure,
        isA<OAuthAccountCollisionFailure>(),
      );
    });
  });

  test('aceita qualquer AuthStrategy sem conhecer o provedor', () async {
    final controller = controllerWith();
    final strategy = _FakeAuthStrategy(
      Ok(FakeAuthRepository.sessionFor('facebook@arenahub.com')),
    );

    await controller.signInWith(strategy);

    expect(strategy.calls, 1);
    expect(controller.session?.user.email, 'facebook@arenahub.com');
  });
}

/// Um provedor que o app ainda não tem: prova que o controller não muda.
class _FakeAuthStrategy implements AuthStrategy {
  _FakeAuthStrategy(this._result);

  final Result<AuthSession> _result;
  int calls = 0;

  @override
  Future<Result<AuthSession>> authenticate() async {
    calls++;
    return _result;
  }
}
