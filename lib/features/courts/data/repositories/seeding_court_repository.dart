import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';

/// Decorador que semeia o catálogo na primeira leitura, quando ele está
/// vazio.
class SeedingCourtRepository implements CourtRepository {
  const SeedingCourtRepository(this._inner, this._seed);

  final CourtRepository _inner;

  /// Grava o catálogo inicial. Devolve falha se não conseguir.
  final Future<Result<void>> Function() _seed;

  @override
  Future<Result<List<Court>>> listAll() async {
    final result = await _inner.listAll();

    if (result case Ok<List<Court>>(value: final courts) when courts.isEmpty) {
      final seeded = await _seed();
      if (seeded case Err<void> error) return error.cast();

      return _inner.listAll();
    }
    return result;
  }

  @override
  Future<Result<Court>> findById(String id) => _inner.findById(id);
}
