import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/data/repositories/firestore_failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Só a tradução de erro é testada: o resto do adaptador conversa com o
/// servidor do Firestore e não roda em teste de unidade.
void main() {
  test('regra não publicada vira mensagem que diz o que fazer', () {
    final failure = failureForFirestore('permission-denied');

    expect(failure, isA<StorageFailure>());
    expect(failure.message, contains('regras'));
  });

  test('falha de rede não é confundida com erro de dados', () {
    expect(failureForFirestore('unavailable'), isA<NetworkFailure>());
    expect(failureForFirestore('deadline-exceeded'), isA<NetworkFailure>());
  });

  test('conflito de gravação vira horário indisponível', () {
    expect(failureForFirestore('already-exists'), isA<SlotUnavailableFailure>());
    expect(failureForFirestore('aborted'), isA<SlotUnavailableFailure>());
  });

  test('código desconhecido não estoura exceção', () {
    expect(failureForFirestore('algo-novo'), isA<StorageFailure>());
  });
}
