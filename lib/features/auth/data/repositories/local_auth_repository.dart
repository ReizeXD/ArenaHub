import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/sign_up_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/password_hasher.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../datasources/user_data_source.dart';
import '../models/user_record.dart';

/// Adaptador de autenticação **offline**.
///
/// Guarda os usuários no dispositivo e emite o próprio token de sessão, então
/// o app roda sem depender de backend.
///
/// Depende de [UserDataSource] e [PasswordHasher] por abstração: nem o banco
/// nem o algoritmo de hash estão amarrados aqui.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(
    this._dataSource,
    this._passwordHasher, {
    this.sessionDuration = const Duration(days: 7),
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? _defaultIdGenerator;

  final UserDataSource _dataSource;
  final PasswordHasher _passwordHasher;
  final String Function() _idGenerator;
  final Duration sessionDuration;

  @override
  Future<Result<AuthSession>> signIn({
    required Email email,
    required Password password,
  }) async {
    final record = await _dataSource.findByEmail(email.value);

    // Mesma falha para e-mail inexistente e senha errada: dizer qual dos dois
    // está errado entregaria de bandeja quais e-mails existem no sistema.
    if (record == null) return const Err(InvalidCredentialsFailure());

    final matches = _passwordHasher.verify(
      plainPassword: password.value,
      hashed: record.passwordHash,
    );
    if (!matches) return const Err(InvalidCredentialsFailure());

    return Ok(_startSession(record.user));
  }

  @override
  Future<Result<AuthSession>> signUp(SignUpData data) async {
    if (await _dataSource.existsByEmail(data.email.value)) {
      return const Err(EmailAlreadyInUseFailure());
    }

    final user = User(
      id: _idGenerator(),
      fullName: data.fullName,
      email: data.email.value,
      role: data.role,
    );

    await _dataSource.insert(
      UserRecord(
        user: user,
        passwordHash: _passwordHasher.hash(data.password.value),
      ),
    );

    return Ok(_startSession(user));
  }

  AuthSession _startSession(User user) {
    final now = DateTime.now();
    return AuthSession(
      user: user,
      token: 'local:${user.id}:${now.millisecondsSinceEpoch}',
      issuedAt: now,
      expiresAt: now.add(sessionDuration),
    );
  }

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
