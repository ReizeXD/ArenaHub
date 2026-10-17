import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/data/datasources/in_memory_user_data_source.dart';
import 'package:arenahub/features/auth/data/repositories/local_auth_repository.dart';
import 'package:arenahub/features/auth/data/services/pbkdf2_password_hasher.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/entities/sign_up_data.dart';
import 'package:arenahub/features/auth/domain/value_objects/email.dart';
import 'package:arenahub/features/auth/domain/value_objects/password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalAuthRepository repository;
  late InMemoryUserDataSource dataSource;

  setUp(() {
    dataSource = InMemoryUserDataSource();
    repository = LocalAuthRepository(
      dataSource,
      Pbkdf2PasswordHasher(iterations: 100),
    );
  });

  Email emailOf(String raw) => (Email.create(raw) as Ok<Email>).value;

  SignUpData dataFor({
    String email = 'dono@arenahub.com',
    String password = 'arena2026',
  }) =>
      SignUpData(
        fullName: 'Ana Ribeiro',
        email: emailOf(email),
        password: (Password.create(password) as Ok<Password>).value,
        role: Role.owner,
      );

  test('cadastra e autentica o mesmo usuário', () async {
    await repository.signUp(dataFor());

    final result = await repository.signIn(
      email: emailOf('dono@arenahub.com'),
      password: Password.unchecked('arena2026'),
    );

    expect(result, isA<Ok<AuthSession>>());
    expect((result as Ok<AuthSession>).value.user.fullName, 'Ana Ribeiro');
  });

  test('guarda a senha apenas como hash', () async {
    await repository.signUp(dataFor());

    final record = await dataSource.findByEmail('dono@arenahub.com');

    expect(record!.passwordHash, isNot(contains('arena2026')));
  });

  test('recusa e-mail já cadastrado', () async {
    await repository.signUp(dataFor());

    final result = await repository.signUp(dataFor());

    expect(
      (result as Err<AuthSession>).failure,
      isA<EmailAlreadyInUseFailure>(),
    );
  });

  test('dá a mesma resposta para e-mail inexistente e senha errada', () async {
    await repository.signUp(dataFor());

    final senhaErrada = await repository.signIn(
      email: emailOf('dono@arenahub.com'),
      password: Password.unchecked('outrasenha1'),
    );
    final naoCadastrado = await repository.signIn(
      email: emailOf('ninguem@arenahub.com'),
      password: Password.unchecked('arena2026'),
    );

    // Diferenciar as duas respostas permitiria descobrir quais e-mails
    // existem no sistema.
    expect(
      (senhaErrada as Err<AuthSession>).failure,
      isA<InvalidCredentialsFailure>(),
    );
    expect(
      (naoCadastrado as Err<AuthSession>).failure,
      isA<InvalidCredentialsFailure>(),
    );
  });

  test('preserva o papel do usuário na sessão', () async {
    final result = await repository.signUp(dataFor());

    expect((result as Ok<AuthSession>).value.user.role, Role.owner);
  });

  test('a sessão emitida ainda é válida', () async {
    final result = await repository.signUp(dataFor());

    expect((result as Ok<AuthSession>).value.isExpired, isFalse);
  });
}
