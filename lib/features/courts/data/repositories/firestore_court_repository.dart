import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';
import '../mappers/court_mapper.dart';
import 'firestore_failures.dart';

/// [CourtRepository] sobre a coleção `courts` do Firestore.
///
/// Segunda implementação do mesmo port — a primeira é a em memória. Nenhum
/// caso de uso, controller ou tela muda para usar uma ou outra.
class FirestoreCourtRepository implements CourtRepository {
  const FirestoreCourtRepository(
    this._firestore, [
    this._mapper = const CourtMapper(),
  ]);

  final FirebaseFirestore _firestore;
  final CourtMapper _mapper;

  static const String collection = 'courts';

  @override
  Future<Result<List<Court>>> listAll() async {
    try {
      final snapshot =
          await _firestore.collection(collection).orderBy('name').get();

      return Ok([
        for (final doc in snapshot.docs) _mapper.fromMap(doc.id, doc.data()),
      ]);
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }

  @override
  Future<Result<Court>> findById(String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      final data = doc.data();
      if (data == null) return const Err(CourtNotFoundFailure());

      return Ok(_mapper.fromMap(doc.id, data));
    } on FirebaseException catch (error) {
      return Err(failureForFirestore(error.code));
    }
  }
}
