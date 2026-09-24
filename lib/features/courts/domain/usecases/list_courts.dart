import '../../../../core/result.dart';
import '../entities/court.dart';
import '../repositories/court_repository.dart';

/// Caso de uso: listar as quadras disponíveis.
class ListCourts {
  const ListCourts(this._courts);

  final CourtRepository _courts;

  Future<Result<List<Court>>> call() => _courts.listAll();
}
