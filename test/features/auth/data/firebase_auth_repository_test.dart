import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:arenahub/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:arenahub/features/auth/data/services/social_auth_service.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes de tradução de erro e fluxos desacoplados do repositório Firebase.
void main() {
  test('credencial recusada vira a mesma falha do adaptador local', () {
    for (final code in [
      'invalid-credential',
      'invalid-login-credentials',
      'wrong-password',
      'user-not-found',
      'user-disabled',
    ]) {
      expect(
        FirebaseAuthRepository.failureFor(code),
        isA<InvalidCredentialsFailure>(),
        reason: code,
      );
    }
  });

  test('mapeia os erros de cadastro', () {
    expect(
      FirebaseAuthRepository.failureFor('email-already-in-use'),
      isA<EmailAlreadyInUseFailure>(),
    );
    expect(
      FirebaseAuthRepository.failureFor('weak-password'),
      isA<WeakPasswordFailure>(),
    );
    expect(
      FirebaseAuthRepository.failureFor('invalid-email'),
      isA<InvalidEmailFailure>(),
    );
  });

  test('falha de rede não é confundida com senha errada', () {
    expect(
      FirebaseAuthRepository.failureFor('network-request-failed'),
      isA<NetworkFailure>(),
    );
  });

  test('código desconhecido não estoura exceção', () {
    expect(
      FirebaseAuthRepository.failureFor('algo-que-o-firebase-inventar'),
      isA<StorageFailure>(),
    );
  });

  group('autenticação social com Firebase', () {
    test('mapeia account-exists-with-different-credential para OAuthAccountCollisionFailure', () {
      expect(
        FirebaseAuthRepository.failureFor('account-exists-with-different-credential'),
        isA<OAuthAccountCollisionFailure>(),
      );
    });

    test('signInWithGoogle retorna OAuthCancelledFailure se o serviço retornar null', () async {
      final repo = FirebaseAuthRepository(
        null,
        FakeProfileSource(),
        googleAuthService: MockGoogleAuthService(payload: null),
      );

      final result = await repo.signInWithGoogle();

      expect((result as Err).failure, isA<OAuthCancelledFailure>());
    });

    test('signInWithGoogle retorna OAuthNetworkFailure em caso de exceção de conexão', () async {
      final repo = FirebaseAuthRepository(
        null,
        FakeProfileSource(),
        googleAuthService: MockGoogleAuthService(throwError: Exception('Falha de rede')),
      );

      final result = await repo.signInWithGoogle();

      expect((result as Err).failure, isA<OAuthNetworkFailure>());
    });

    test('signInWithApple retorna OAuthCancelledFailure se o serviço retornar null', () async {
      final repo = FirebaseAuthRepository(
        null,
        FakeProfileSource(),
        appleAuthService: MockAppleAuthService(payload: null),
      );

      final result = await repo.signInWithApple();

      expect((result as Err).failure, isA<OAuthCancelledFailure>());
    });

    test('signInWithApple retorna OAuthNetworkFailure em caso de exceção de conexão', () async {
      final repo = FirebaseAuthRepository(
        null,
        FakeProfileSource(),
        appleAuthService: MockAppleAuthService(throwError: Exception('Falha de rede')),
      );

      final result = await repo.signInWithApple();

      expect((result as Err).failure, isA<OAuthNetworkFailure>());
    });
  });

  group('perfil é opcional', () {
    test('sem Firestore, o login não quebra — fica sem perfil', () async {
      final profile = await FirebaseAuthRepository.profileOrNull(
        BrokenProfileSource(),
        'uid-1',
      );

      // Quem chama trata null como "papel de jogador", o menor privilégio.
      expect(profile, isNull);
    });

    test('sem Firestore, o cadastro avisa que não gravou em vez de estourar',
        () async {
      final saved = await FirebaseAuthRepository.saveProfileQuietly(
        BrokenProfileSource(),
        'uid-1',
        const UserProfile(fullName: 'Ana Ribeiro', role: Role.owner),
      );

      expect(saved, isFalse);
    });

    test('com Firestore, o papel sobrevive à ida e volta', () async {
      final source = FakeProfileSource();

      await FirebaseAuthRepository.saveProfileQuietly(
        source,
        'uid-1',
        const UserProfile(fullName: 'Ana Ribeiro', role: Role.owner),
      );
      final profile =
          await FirebaseAuthRepository.profileOrNull(source, 'uid-1');

      expect(profile?.role, Role.owner);
      expect(profile?.fullName, 'Ana Ribeiro');
    });
  });
}

/// Dublê de serviço de autenticação Google.
class MockGoogleAuthService implements GoogleAuthService {
  MockGoogleAuthService({this.payload, this.throwError});
  final SocialAuthPayload? payload;
  final Object? throwError;

  @override
  Future<SocialAuthPayload?> signIn() async {
    if (throwError != null) throw throwError!;
    return payload;
  }
}

/// Dublê de serviço de autenticação Apple.
class MockAppleAuthService implements AppleAuthService {
  MockAppleAuthService({this.payload, this.throwError});
  final SocialAuthPayload? payload;
  final Object? throwError;

  @override
  Future<SocialAuthPayload?> signIn() async {
    if (throwError != null) throw throwError!;
    return payload;
  }
}

/// Perfil que sempre falha — simula projeto sem Firestore criado, ou regra
/// negando a leitura.
class BrokenProfileSource implements UserProfileDataSource {
  @override
  Future<UserProfile?> find(String uid) async => throw StateError('sem Firestore');

  @override
  Future<void> save(String uid, UserProfile profile) async =>
      throw StateError('sem Firestore');
}

/// Perfil em memória, para o caminho feliz.
class FakeProfileSource implements UserProfileDataSource {
  final Map<String, UserProfile> saved = {};

  @override
  Future<UserProfile?> find(String uid) async => saved[uid];

  @override
  Future<void> save(String uid, UserProfile profile) async => saved[uid] = profile;
}
