import '../../../../core/result.dart';
import '../entities/court.dart';
import '../repositories/court_repository.dart';

/// Caso de uso: listar as quadras cadastradas pelo dono.
class ListMyCourts {
  const ListMyCourts(this._courts);

  final CourtRepository _courts;

  Future<Result<List<Court>>> call(String ownerId) =>
      _courts.listByOwner(ownerId);
}