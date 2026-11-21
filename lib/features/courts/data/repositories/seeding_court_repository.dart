import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/repositories/court_repository.dart';
import '../seed/demo_courts.dart';

/// Decorador que semeia o catálogo na primeira leitura, quando ele está
/// vazio, e completa a foto das quadras do catálogo gravadas sem ela.
class SeedingCourtRepository implements CourtRepository {
  const SeedingCourtRepository(
    this._inner,
    this._seed, [
    this._catalog = demoCourts,
  ]);

  final CourtRepository _inner;
  final List<Court> _catalog;

  /// Grava o catálogo inicial. Devolve falha se não conseguir.
  final Future<Result<void>> Function() _seed;

  @override
  String nextIdentity() => _inner.nextIdentity();

  @override
  Future<Result<List<Court>>> listAll() async {
    final result = await _inner.listAll();

    if (result is Ok<List<Court>>) {
      final courts = result.value;
      if (courts.isEmpty) {
        final seeded = await _seed();
        if (seeded is Err<void>) {
          return Err(seeded.failure);
        }
        return _inner.listAll();
      }
      return Ok(await _backfillImages(courts));
    }
    return result;
  }

  Future<List<Court>> _backfillImages(List<Court> courts) async {
    final catalogImages = <String, String>{};
    for (final court in _catalog) {
      if (court.imageUrl.isNotEmpty) {
        catalogImages[court.id] = court.imageUrl;
      }
    }

    final updatedCourts = <Court>[];
    for (final court in courts) {
      updatedCourts.add(await _withCatalogImage(court, catalogImages[court.id]));
    }
    return updatedCourts;
  }

  Future<Court> _withCatalogImage(Court court, String? catalogImage) async {
    if (catalogImage == null || court.imageUrl.isNotEmpty) return court;

    final patched = court.copyWith(imageUrl: catalogImage);
    final saved = await _inner.update(patched);
    return saved is Ok<Court> ? patched : court;
  }

  @override
  Future<Result<List<Court>>> listByOwner(String ownerId) =>
      _inner.listByOwner(ownerId);

  @override
  Future<Result<Court>> findById(String id) => _inner.findById(id);

  @override
  Future<Result<Court>> create(Court court) => _inner.create(court);

  @override
  Future<Result<Court>> update(Court court) => _inner.update(court);

  @override
  Future<Result<void>> delete(String id) => _inner.delete(id);
}
