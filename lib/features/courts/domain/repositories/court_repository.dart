import '../../../../core/result.dart';
import '../entities/court.dart';

/// Port de leitura e escrita das quadras.
abstract interface class CourtRepository {
  /// Gera o próximo identificador único válido para uma quadra de acordo
  /// com a infraestrutura/persistência subjacente.
  String nextIdentity();

  Future<Result<List<Court>>> listAll();

  Future<Result<List<Court>>> listByOwner(String ownerId);

  Future<Result<Court>> findById(String id);

  Future<Result<Court>> create(Court court);

  Future<Result<Court>> update(Court court);

  Future<Result<void>> delete(String id);
}
