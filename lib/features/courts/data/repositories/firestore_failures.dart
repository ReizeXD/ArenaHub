import '../../../../core/failure.dart';

/// Traduz o código de erro do Firestore para o vocabulário de falhas do
/// domínio.
///
/// É o que mantém a substituição de Liskov de pé: a tela reage igual a um
/// erro, venha ele da memória ou do Firestore. Função de topo para poder ser
/// testada sem subir o Firebase.
Failure failureForFirestore(String code) => switch (code) {
      'permission-denied' => const StorageFailure(
          'Sem permissão para acessar estes dados. '
          'As regras do Firestore foram publicadas?',
        ),
      'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
      'not-found' => const CourtNotFoundFailure(),
      'already-exists' || 'aborted' => const SlotUnavailableFailure(),
      _ => const StorageFailure('Não foi possível acessar os dados.'),
    };
