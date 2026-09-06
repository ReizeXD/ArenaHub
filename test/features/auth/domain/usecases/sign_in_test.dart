import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemorySessionStorage sessionStorage;

  setUp(() {
    repository = FakeAuthRepository();
    sessionStorage = InMemorySessionStorage();
  });

  test('salva a sessão quando as credenciais são aceitas', () async {
    final result = await SignIn(repository, sessionStorage)(
      email: 'jogador@arenahub.com',
      password: 'arena2026',
    );

    expect(result, isA<Ok<AuthSession>>());
    expect(sessionStorage.saveCalls, 1);
    expect(await sessionStorage.read(), isNotNull);
  });

  test('nem chega ao repositório quando o e-mail é inválido', () async {
    final result = await SignIn(repository, sessionStorage)(
      email: 'jogador@',
      password: 'arena2026',
    );

    expect((result as Err<AuthSession>).failure, isA<InvalidEmailFailure>());
    expect(repository.signInCalls, 0, reason: 'validação vem antes da E/S');
    expect(sessionStorage.saveCalls, 0);
  });

  test('não guarda sessão quando o repositório recusa as credenciais', () async {
    final signIn = SignIn(
      FakeAuthRepository(failure: const InvalidCredentialsFailure()),
      sessionStorage,
    );

    final result = await signIn(
      email: 'jogador@arenahub.com',
      password: 'senhaerrada1',
    );

    expect(
      (result as Err<AuthSession>).failure,
      isA<InvalidCredentialsFailure>(),
    );
    expect(sessionStorage.saveCalls, 0);
  });

  test('normaliza o e-mail antes de repassar ao repositório', () async {
    await SignIn(repository, sessionStorage)(
      email: '  Jogador@ArenaHub.COM ',
      password: 'arena2026',
    );

    expect(repository.lastEmail?.value, 'jogador@arenahub.com');
  });
}
