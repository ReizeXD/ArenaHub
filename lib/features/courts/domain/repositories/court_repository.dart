import '../../../../core/result.dart';
import '../entities/court.dart';

/// Port de leitura das quadras.
///
/// Como o `AuthRepository`, existe para que os casos de uso não saibam se as
/// quadras vêm de uma lista em memória, do Firestore ou de uma API.
abstract interface class CourtRepository {
  Future<Result<List<Court>>> listAll();

  Future<Result<Court>> findById(String id);
}
