import '../../../../core/failure.dart';

/// Traduz o código de erro do Firestore para o vocabulário de falhas do
/// domínio.
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
