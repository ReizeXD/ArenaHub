import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/result.dart';
import '../mappers/court_mapper.dart';
import '../repositories/firestore_court_repository.dart';
import '../repositories/firestore_failures.dart';
import 'demo_courts.dart';

/// Grava o catálogo inicial de quadras no Firestore.
///
/// Uma escrita em lote: ou entram todas, ou nenhuma.
class FirestoreCourtSeeder {
  const FirestoreCourtSeeder(
    this._firestore, [
    this._mapper = const CourtMapper(),
  ]);

  final FirebaseFirestore _firestore;
  final CourtMapper _mapper;

  Future<Result<void>> seed() async {
    try {
      final batch = _firestore.batch();
      final collection =
          _firestore.collection(FirestoreCourtRepository.collection);

      for (final court in demoCourts) {
        batch.set(collection.doc(court.id), _mapper.toMap(court));
      }
      await batch.commit();

      return const Ok<void>(null);
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }
}
