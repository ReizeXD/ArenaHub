import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/entities/sign_up_data.dart';
import 'package:arenahub/features/auth/domain/entities/user.dart';
import 'package:arenahub/features/auth/domain/repositories/auth_repository.dart';
import 'package:arenahub/features/auth/domain/services/session_storage.dart';
import 'package:arenahub/features/auth/domain/usecases/get_current_session.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_in.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_out.dart';
import 'package:arenahub/features/auth/domain/usecases/sign_up.dart';
import 'package:arenahub/features/auth/domain/value_objects/email.dart';
import 'package:arenahub/features/auth/domain/value_objects/password.dart';
import 'package:arenahub/features/auth/presentation/controllers/auth_controller.dart';

/// Dublê de [AuthRepository].
///
/// Poder testar os casos de uso sem banco, sem rede e sem Flutter é a prova
/// mais direta de que a inversão de dependência está de pé: o teste é só
/// mais uma implementação do mesmo port.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failure});

  /// Quando preenchido, toda operação falha com este erro.
  final Failure? failure;

  int signInCalls = 0;
  int signUpCalls = 0;
  Email? lastEmail;

  @override
  Future<Result<AuthSession>> signIn({
    required Email email,
    required Password password,
  }) async {
    signInCalls++;
    lastEmail = email;

    final error = failure;
    if (error != null) return Err(error);
    return Ok(sessionFor(email.value));
  }

  @override
  Future<Result<AuthSession>> signUp(SignUpData data) async {
    signUpCalls++;

    final error = failure;
    if (error != null) return Err(error);
    return Ok(sessionFor(data.email.value, fullName: data.fullName));
  }

  static AuthSession sessionFor(
    String email, {
    String fullName = 'Craque da Bola',
    Role role = Role.player,
    Duration validFor = const Duration(days: 1),
  }) {
    final now = DateTime.now();
    return AuthSession(
      token: 'fake-token',
      issuedAt: now,
      expiresAt: now.add(validFor),
      user: User(id: 'user-1', fullName: fullName, email: email, role: role),
    );
  }
}

/// Dublê de [SessionStorage] guardando a sessão em memória.
class InMemorySessionStorage implements SessionStorage {
  AuthSession? _session;

  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> save(AuthSession session) async {
    saveCalls++;
    _session = session;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _session = null;
  }

  /// Semeia uma sessão já existente, como se o app tivesse sido reaberto.
  void seed(AuthSession session) => _session = session;
}

/// Monta um [AuthController] sobre dublês — o mesmo arranjo que o composition
/// root faz com as implementações reais.
AuthController controllerWith({
  AuthRepository? repository,
  SessionStorage? storage,
}) {
  final repo = repository ?? FakeAuthRepository();
  final store = storage ?? InMemorySessionStorage();

  return AuthController(
    SignIn(repo, store),
    SignUp(repo, store),
    SignOut(store),
    GetCurrentSession(store),
  );
}
