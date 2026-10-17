import '../../../../core/result.dart';
import '../entities/court.dart';

/// Port de leitura das quadras.
abstract interface class CourtRepository {
  Future<Result<List<Court>>> listAll();

  Future<Result<Court>> findById(String id);
}
