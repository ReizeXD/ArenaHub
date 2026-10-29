import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/create_court.dart';
import 'package:arenahub/features/courts/domain/usecases/delete_court.dart';
import 'package:arenahub/features/courts/domain/usecases/list_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/update_court.dart';
import 'package:arenahub/features/courts/presentation/controllers/courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/states/my_courts_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late InMemoryCourtRepository repository;
  late FakeCourtImageStorage imageStorage;
  late MyCourtsController controller;
  var mutationCount = 0;

  const myCourt = Court(
    id: 'quadra-minha',
    ownerId: 'dono-1',
    name: 'Minha Arena',
    sport: Sport.beachTennis,
    address: 'Rua das Flores, 10',
    pricePerHourInCents: 11000,
  );

  const otherCourt = Court(
    id: 'quadra-outra',
    ownerId: 'dono-2',
    name: 'Outra Arena',
    sport: Sport.futsal,
    address: 'Rua do Sol, 20',
    pricePerHourInCents: 9000,
  );

  setUp(() {
    mutationCount = 0;
    repository = InMemoryCourtRepository([myCourt, otherCourt]);
    imageStorage = FakeCourtImageStorage();
    controller = MyCourtsController(
      listMyCourts: ListMyCourts(repository),
      createCourt: CreateCourt(repository, imageStorage),
      updateCourt: UpdateCourt(repository, imageStorage),
      deleteCourt: DeleteCourt(repository),
      onCourtMutated: () => mutationCount++,
    );
  });

  group('MyCourtsController — ciclo de carregamento', () {
    test('começa com estado MyCourtsLoading e lista vazia', () {
      expect(controller.state, isA<MyCourtsLoading>());
      expect(controller.courts, isEmpty);
      expect(controller.currentOwnerId, isNull);
    });

    test('carrega as quadras do dono informado', () async {
      await controller.load('dono-1');

      expect(controller.state, isA<MyCourtsLoaded>());
      expect(controller.courts.map((c) => c.id), ['quadra-minha']);
      expect(controller.currentOwnerId, 'dono-1');
    });

    test('emite MyCourtsFailed quando o repositório falha', () async {
      final failing = MyCourtsController(
        listMyCourts: ListMyCourts(const FailingCourtRepository()),
        createCourt: CreateCourt(repository, imageStorage),
        updateCourt: UpdateCourt(repository, imageStorage),
        deleteCourt: DeleteCourt(repository),
      );

      await failing.load('qualquer');

      expect(failing.state, isA<MyCourtsFailed>());
      expect(failing.courts, isEmpty);
    });
  });

  group('MyCourtsController — operações de mutação', () {
    test('create cadastra nova quadra, recarrega lista e dispara onCourtMutated',
        () async {
      await controller.load('dono-1');
      expect(controller.courts, hasLength(1));

      final result = await controller.create(
        ownerId: 'dono-1',
        name: 'Segunda Quadra',
        sport: Sport.volleyball,
        address: 'Rua Nova, 50',
        pricePerHourInCents: 8500,
      );

      expect(result, isA<Ok<Court>>());
      expect(controller.courts, hasLength(2));
      expect(controller.courts.map((c) => c.name),
          contains('Segunda Quadra'));
      expect(mutationCount, 1,
          reason: 'onCourtMutated deve ser chamado em mutações bem-sucedidas');
    });

    test('create com dados inválidos não altera lista nem dispara callback',
        () async {
      await controller.load('dono-1');

      final result = await controller.create(
        ownerId: 'dono-1',
        name: '', // nome inválido
        sport: Sport.futsal,
        address: 'Rua Válida',
        pricePerHourInCents: 5000,
      );

      expect(result, isA<Err<Court>>());
      expect((result as Err<Court>).failure, isA<InvalidCourtNameFailure>());
      expect(controller.courts, hasLength(1));
      expect(mutationCount, 0);
    });

    test('update altera quadra, recarrega lista e dispara onCourtMutated',
        () async {
      await controller.load('dono-1');

      final result = await controller.update(
        existing: myCourt,
        userId: 'dono-1',
        name: 'Minha Arena Atualizada',
        sport: myCourt.sport,
        address: myCourt.address,
        pricePerHourInCents: 15000,
      );

      expect(result, isA<Ok<Court>>());
      expect(controller.courts.first.name, 'Minha Arena Atualizada');
      expect(controller.courts.first.pricePerHourInCents, 15000);
      expect(mutationCount, 1);
    });

    test('update de usuário não proprietário falha e não dispara callback',
        () async {
      await controller.load('dono-1');

      final result = await controller.update(
        existing: myCourt,
        userId: 'invasor',
        name: 'Nome Alterado',
        sport: myCourt.sport,
        address: myCourt.address,
        pricePerHourInCents: myCourt.pricePerHourInCents,
      );

      expect(result, isA<Err<Court>>());
      expect((result as Err<Court>).failure, isA<UnauthorizedCourtActionFailure>());
      expect(mutationCount, 0);
    });

    test('delete exclui quadra, recarrega lista e dispara onCourtMutated',
        () async {
      await controller.load('dono-1');
      expect(controller.courts, hasLength(1));

      final result = await controller.delete(
        court: myCourt,
        userId: 'dono-1',
      );

      expect(result, isA<Ok<void>>());
      expect(controller.courts, isEmpty);
      expect(mutationCount, 1);
    });

    test('delete por usuário não proprietário falha e não remove quadra',
        () async {
      await controller.load('dono-1');

      final result = await controller.delete(
        court: myCourt,
        userId: 'invasor',
      );

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<UnauthorizedCourtActionFailure>());
      expect(controller.courts, hasLength(1));
      expect(mutationCount, 0);
    });
  });

  group('Sincronização entre Controllers', () {
    test('alterações em MyCourtsController sincronizam CourtsController',
        () async {
      final courtsController = CourtsController(ListCourts(repository));
      await courtsController.load();
      expect(courtsController.visibleCourts, hasLength(2));

      // Configura MyCourtsController com sincronização do catálogo geral
      final syncedMyCourtsController = MyCourtsController(
        listMyCourts: ListMyCourts(repository),
        createCourt: CreateCourt(repository, imageStorage),
        updateCourt: UpdateCourt(repository, imageStorage),
        deleteCourt: DeleteCourt(repository),
        onCourtMutated: () => courtsController.load(),
      );

      await syncedMyCourtsController.load('dono-1');

      // Cria uma nova quadra pelo dono
      await syncedMyCourtsController.create(
        ownerId: 'dono-1',
        name: 'Quadra Nova Sincronizada',
        sport: Sport.society,
        address: 'Rua Nova, 1',
        pricePerHourInCents: 15000,
      );

      // Catálogo geral deve conter 3 quadras automaticamente
      expect(courtsController.visibleCourts, hasLength(3));
      expect(
        courtsController.visibleCourts.map((c) => c.name),
        contains('Quadra Nova Sincronizada'),
      );

      // Exclui a quadra pelo dono
      final quadraCriada = courtsController.visibleCourts
          .firstWhere((c) => c.name == 'Quadra Nova Sincronizada');
      await syncedMyCourtsController.delete(
        court: quadraCriada,
        userId: 'dono-1',
      );

      // Catálogo geral reflete a exclusão
      expect(courtsController.visibleCourts, hasLength(2));
      expect(
        courtsController.visibleCourts.map((c) => c.name),
        isNot(contains('Quadra Nova Sincronizada')),
      );
    });
  });
}
