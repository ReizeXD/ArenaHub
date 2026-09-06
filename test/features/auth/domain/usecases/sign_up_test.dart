import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemorySessionStorage sessionStorage;

  setUp(() {
    repository = FakeAuthRepository();
    sessionStorage = InMemorySessionStorage();
  });

  Future<Result<AuthSession>> register({
    String fullName = 'Ana Ribeiro',
    String email = 'dono@arenahub.com',
    String password = 'arena2026',
    Role role = Role.owner,
  }) =>
      SignUp(repository, sessionStorage)(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );

  test('cria a conta e já deixa o usuário logado', () async {
    final result = await register();

    expect(result, isA<Ok<AuthSession>>());
    expect(sessionStorage.saveCalls, 1);
  });

  test('recusa nome sem sobrenome', () async {
    final result = await register(fullName: 'Ana');

    expect((result as Err<AuthSession>).failure, isA<InvalidNameFailure>());
    expect(repository.signUpCalls, 0);
  });

  test('recusa senha fraca antes de tocar no repositório', () async {
    final result = await register(password: '123456');

    expect((result as Err<AuthSession>).failure, isA<WeakPasswordFailure>());
    expect(repository.signUpCalls, 0);
  });

  test('propaga e-mail já cadastrado sem salvar sessão', () async {
    final signUp = SignUp(
      FakeAuthRepository(failure: const EmailAlreadyInUseFailure()),
      sessionStorage,
    );

    final result = await signUp(
      fullName: 'Ana Ribeiro',
      email: 'dono@arenahub.com',
      password: 'arena2026',
      role: Role.owner,
    );

    expect(
      (result as Err<AuthSession>).failure,
      isA<EmailAlreadyInUseFailure>(),
    );
    expect(sessionStorage.saveCalls, 0);
  });

  test('preserva o papel escolhido', () async {
    await register(role: Role.owner);

    expect(repository.signUpCalls, 1);
  });
}
