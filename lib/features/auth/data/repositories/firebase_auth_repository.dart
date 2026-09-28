import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/sign_up_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../datasources/user_profile_data_source.dart';

/// Adaptador de autenticação sobre o **Firebase**.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(
    this._auth,
    this._profiles, {
    this.sessionDuration = const Duration(days: 7),
  });

  final fb.FirebaseAuth _auth;
  final UserProfileDataSource _profiles;

  /// Por quanto tempo a sessão salva no aparelho continua valendo.
  final Duration sessionDuration;

  @override
  Future<Result<AuthSession>> signIn({
    required Email email,
    required Password password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.value,
        password: password.value,
      );
      return Ok(await _sessionFor(credential.user!));
    } on fb.FirebaseAuthException catch (error) {
      return Err(failureFor(error.code));
    }
  }

  @override
  Future<Result<AuthSession>> signUp(SignUpData data) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: data.email.value,
        password: data.password.value,
      );
      final firebaseUser = credential.user!;

      // A conta já existe no Auth neste ponto. Falhar aqui deixaria um
      // usuário órfão, sem conseguir entrar — então grava sem derrubar.
      await saveProfileQuietly(
        _profiles,
        firebaseUser.uid,
        UserProfile(fullName: data.fullName, role: data.role),
      );
      await firebaseUser.updateDisplayName(data.fullName);

      return Ok(
        await _sessionFor(
          firebaseUser,
          profile: UserProfile(fullName: data.fullName, role: data.role),
        ),
      );
    } on fb.FirebaseAuthException catch (error) {
      return Err(failureFor(error.code));
    }
  }

  Future<AuthSession> _sessionFor(
    fb.User firebaseUser, {
    UserProfile? profile,
  }) async {
    final resolved = profile ?? await profileOrNull(_profiles, firebaseUser.uid);
    final token = await firebaseUser.getIdTokenResult();
    final issuedAt = token.issuedAtTime ?? DateTime.now();

    return AuthSession(
      user: User(
        id: firebaseUser.uid,
        fullName: resolved?.fullName ??
            firebaseUser.displayName ??
            firebaseUser.email!.split('@').first,
        email: firebaseUser.email!,
        // Sem perfil gravado, o menor privilégio: jogador.
        role: resolved?.role ?? Role.player,
      ),
      // Instantâneo do token no momento do login. Para uma chamada
      // autenticada a uma API, peça um novo com `getIdToken()` em vez de
      // reaproveitar este.
      token: token.token ?? '',
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(sessionDuration),
    );
  }

  /// Busca o perfil tolerando falha.
  static Future<UserProfile?> profileOrNull(
    UserProfileDataSource profiles,
    String uid,
  ) async {
    try {
      return await profiles.find(uid);
    } on Object {
      return null;
    }
  }

  /// Grava o perfil tolerando falha, pelo mesmo motivo de [profileOrNull].
  static Future<bool> saveProfileQuietly(
    UserProfileDataSource profiles,
    String uid,
    UserProfile profile,
  ) async {
    try {
      await profiles.save(uid, profile);
      return true;
    } on Object {
      return false;
    }
  }

  /// Traduz o código de erro do Firebase para o vocabulário de falhas do
  /// domínio.
  static Failure failureFor(String code) => switch (code) {
        'invalid-credential' ||
        'invalid-login-credentials' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' =>
          const InvalidCredentialsFailure(),
        'invalid-email' => const InvalidEmailFailure(),
        'email-already-in-use' => const EmailAlreadyInUseFailure(),
        'weak-password' => const WeakPasswordFailure(),
        'network-request-failed' || 'too-many-requests' =>
          const NetworkFailure(),
        _ => const StorageFailure('Não foi possível concluir a operação.'),
      };
}
