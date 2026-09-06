import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/data/repositories/firebase_auth_repository.dart';
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
}
