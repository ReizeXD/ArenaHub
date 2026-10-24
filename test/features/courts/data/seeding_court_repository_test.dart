import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/data/repositories/seeding_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/repositories/court_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

/// Repositório que começa vazio e ganha conteúdo quando alguém semeia.
class GrowableCourtRepository implements CourtRepository {
  final List<Court> courts = <Court>[];

  int listCalls = 0;

  @override
  String nextIdentity() => 'court_${courts.length + 1}';

  @override
  Future<Result<List<Court>>> listAll() async {
    listCalls++;
    return Ok(List.of(courts));
  }

  @override
  Future<Result<List<Court>>> listByOwner(String ownerId) async =>
      Ok(courts.where((c) => c.ownerId == ownerId).toList());

  @override
  Future<Result<Court>> findById(String id) async => const Err(
        CourtNotFoundFailure(),
      );

  @override
  Future<Result<Court>> create(Court court) async {
    courts.add(court);
    return Ok(court);
  }

  @override
  Future<Result<Court>> update(Court court) async {
    final index = courts.indexWhere((c) => c.id == court.id);
    if (index == -1) return const Err(CourtNotFoundFailure());
    courts[index] = court;
    return Ok(court);
  }

  @override
  Future<Result<void>> delete(String id) async {
    courts.removeWhere((c) => c.id == id);
    return const Ok(null);
  }
}

void main() {
  test('semeia quando o catálogo está vazio e devolve o resultado', () async {
    final inner = GrowableCourtRepository();
    var seedCalls = 0;

    final repository = SeedingCourtRepository(inner, () async {
      seedCalls++;
      inner.courts.add(testCourt);
      return const Ok<void>(null);
    });

    final result = await repository.listAll();

    expect(seedCalls, 1);
    expect((result as Ok<List<Court>>).value, hasLength(1));
    expect(inner.listCalls, 2, reason: 'relê depois de semear');
  });

  test('não semeia quando já existem quadras', () async {
    var seedCalls = 0;

    final repository = SeedingCourtRepository(
      InMemoryCourtRepository(),
      () async {
        seedCalls++;
        return const Ok<void>(null);
      },
    );

    await repository.listAll();

    expect(seedCalls, 0);
  });

  test('propaga a falha quando a semeadura não consegue gravar', () async {
    final repository = SeedingCourtRepository(
      GrowableCourtRepository(),
      () async => const Err<void>(StorageFailure('sem permissão')),
    );

    final result = await repository.listAll();

    expect((result as Err<List<Court>>).failure, isA<StorageFailure>());
  });

  test('busca por id passa direto, sem semear', () async {
    var seedCalls = 0;
    final repository = SeedingCourtRepository(
      InMemoryCourtRepository(),
      () async {
        seedCalls++;
        return const Ok<void>(null);
      },
    );

    final result = await repository.findById('pajucara');

    expect((result as Ok<Court>).value.name, 'Quadra Pajuçara');
    expect(seedCalls, 0);
  });
}
