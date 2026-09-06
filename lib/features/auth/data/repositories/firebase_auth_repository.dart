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
///
/// Segunda implementação de [AuthRepository], irmã de `LocalAuthRepository`.
/// Nenhum caso de uso, controller ou tela muda para usá-la — só a linha do
/// composition root que escolhe qual das duas instanciar.
///
/// Divisão de trabalho: o Firebase Auth cuida da credencial (e do hash da
/// senha, no servidor dele); o [UserProfileDataSource] cuida de nome e papel,
/// que o Auth não armazena.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth, this._profiles);

  final fb.FirebaseAuth _auth;
  final UserProfileDataSource _profiles;

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

      await _profiles.save(
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
    final resolved = profile ?? await _profiles.find(firebaseUser.uid);
    final token = await firebaseUser.getIdTokenResult();

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
      token: token.token ?? '',
      issuedAt: token.issuedAtTime ?? DateTime.now(),
      expiresAt:
          token.expirationTime ?? DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// Traduz o código de erro do Firebase para o vocabulário de falhas do
  /// domínio.
  ///
  /// É o que mantém a substituição de Liskov de pé: quem chama trata
  /// `InvalidCredentialsFailure` igual, venha ela do SQLite ou do Firebase.
  /// Público para poder ser testado sem subir o Firebase.
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
