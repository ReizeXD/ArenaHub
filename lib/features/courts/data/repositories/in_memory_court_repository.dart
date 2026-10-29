import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';
import '../seed/demo_courts.dart';

/// [CourtRepository] servindo um catálogo em memória com suporte a CRUD.
class InMemoryCourtRepository implements CourtRepository {
  InMemoryCourtRepository([List<Court>? courts])
      : _courts = courts != null
            ? List<Court>.of(courts)
            : List<Court>.of(demoCourts);

  final List<Court> _courts;
  int _nextId = 0;

  @override
  String nextIdentity() =>
      'court_${DateTime.now().microsecondsSinceEpoch}_${++_nextId}';

  @override
  Future<Result<List<Court>>> listAll() async => Ok(List.unmodifiable(_courts));

  @override
  Future<Result<List<Court>>> listByOwner(String ownerId) async =>
      Ok(_courts.where((court) => court.ownerId == ownerId).toList());

  @override
  Future<Result<Court>> findById(String id) async {
    for (final court in _courts) {
      if (court.id == id) return Ok(court);
    }
    return const Err(CourtNotFoundFailure());
  }

  @override
  Future<Result<Court>> create(Court court) async {
    _courts.add(court);
    return Ok(court);
  }

  @override
  Future<Result<Court>> update(Court court) async {
    final index = _courts.indexWhere((c) => c.id == court.id);
    if (index == -1) return const Err(CourtNotFoundFailure());
    _courts[index] = court;
    return Ok(court);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _courts.removeWhere((c) => c.id == id);
    return const Ok(null);
  }
}
