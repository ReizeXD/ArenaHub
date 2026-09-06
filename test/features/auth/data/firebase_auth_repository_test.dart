import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/data/datasources/user_profile_data_source.dart';
import 'package:arenahub/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Só a tradução de erro é testada aqui: o resto do adaptador conversa com o
/// servidor do Firebase e não roda em teste de unidade. Ainda assim, é esta
/// tradução que garante que a tela reaja igual venha o erro de onde vier.
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
