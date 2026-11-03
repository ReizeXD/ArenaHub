import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemorySessionStorage sessionStorage;

  setUp(() {
    repository = FakeAuthRepository();
    sessionStorage = InMemorySessionStorage();
  });

  test('autentica com sucesso e salva a sessao quando o repositorio aceita', () async {
    final useCase = SignInWithGoogle(repository, sessionStorage);

    final result = await useCase();

    expect(result, isA<Ok<AuthSession>>());
    expect(repository.signInWithGoogleCalls, 1);
    expect(sessionStorage.saveCalls, 1);

    final session = (result as Ok<AuthSession>).value;
    expect(session.user.email, 'atleta.google@arenahub.com');
    expect(session.user.fullName, 'Atleta Google');
  });

  test('propaga cancelamento pelo usuario e nao salva sessao', () async {
    final repoWithCancel = FakeAuthRepository(
      failure: const OAuthCancelledFailure(),
    );
    final useCase = SignInWithGoogle(repoWithCancel, sessionStorage);

    final result = await useCase();

    expect((result as Err<AuthSession>).failure, isA<OAuthCancelledFailure>());
    expect(sessionStorage.saveCalls, 0);
  });

  test('propaga falha de rede e nao salva sessao', () async {
    final repoWithNetworkError = FakeAuthRepository(
      failure: const OAuthNetworkFailure(),
    );
    final useCase = SignInWithGoogle(repoWithNetworkError, sessionStorage);

    final result = await useCase();

    expect((result as Err<AuthSession>).failure, isA<OAuthNetworkFailure>());
    expect(sessionStorage.saveCalls, 0);
  });

  test('propaga colisao de contas quando e-mail ja existe em outro metodo', () async {
    final repoWithCollision = FakeAuthRepository(
      failure: const OAuthAccountCollisionFailure(),
    );
    final useCase = SignInWithGoogle(repoWithCollision, sessionStorage);

    final result = await useCase();

    expect((result as Err<AuthSession>).failure, isA<OAuthAccountCollisionFailure>());
    expect(sessionStorage.saveCalls, 0);
  });

  test('funciona sem sessionStorage opcional informado', () async {
    final useCase = SignInWithGoogle(repository);

    final result = await useCase();

    expect(result, isA<Ok<AuthSession>>());
    expect(repository.signInWithGoogleCalls, 1);
  });
}
