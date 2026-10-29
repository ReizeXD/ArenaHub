import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/create_court.dart';
import 'package:arenahub/features/courts/domain/usecases/delete_court.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/update_court.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/pages/my_courts_page.dart';
import 'package:arenahub/features/courts/presentation/states/my_courts_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late InMemoryCourtRepository repository;
  late FakeCourtImageStorage imageStorage;
  late MyCourtsController controller;

  const ownerId = 'owner-10';

  const court1 = Court(
    id: 'court-1',
    ownerId: ownerId,
    name: 'Quadra Central de Beach Tennis',
    sport: Sport.beachTennis,
    address: 'Av. Brasil, 500',
    pricePerHourInCents: 13000,
    openingHour: 8,
    closingHour: 22,
  );

  const court2 = Court(
    id: 'court-2',
    ownerId: ownerId,
    name: 'Arena Society Gol',
    sport: Sport.society,
    address: 'Rua do Esporte, 100',
    pricePerHourInCents: 18000,
    openingHour: 7,
    closingHour: 23,
  );

  setUp(() {
    repository = InMemoryCourtRepository([court1, court2]);
    imageStorage = FakeCourtImageStorage();
    controller = MyCourtsController(
      listMyCourts: ListMyCourts(repository),
      createCourt: CreateCourt(repository, imageStorage),
      updateCourt: UpdateCourt(repository, imageStorage),
      deleteCourt: DeleteCourt(repository),
    );
  });

  Widget buildSubject({
    MyCourtsController? customController,
    void Function(Court court)? onViewCourtAgenda,
  }) {
    return MaterialApp(
      home: MyCourtsPage(
        ownerId: ownerId,
        controller: customController ?? controller,
        onViewCourtAgenda: onViewCourtAgenda,
      ),
    );
  }

  group('MyCourtsPage', () {
    testWidgets('exibe loading indicador no estado inicial MyCourtsLoading',
        (tester) async {
      final unstartedController = MyCourtsController(
        listMyCourts: ListMyCourts(repository),
        createCourt: CreateCourt(repository, imageStorage),
        updateCourt: UpdateCourt(repository, imageStorage),
        deleteCourt: DeleteCourt(repository),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: switch (unstartedController.state) {
                MyCourtsLoading() => const CircularProgressIndicator(),
                _ => const SizedBox(),
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('exibe estado vazio convidando ao cadastro quando não há quadras',
        (tester) async {
      final emptyRepo = InMemoryCourtRepository([]);
      final emptyController = MyCourtsController(
        listMyCourts: ListMyCourts(emptyRepo),
        createCourt: CreateCourt(emptyRepo, imageStorage),
        updateCourt: UpdateCourt(emptyRepo, imageStorage),
        deleteCourt: DeleteCourt(emptyRepo),
      );

      await tester.pumpWidget(buildSubject(customController: emptyController));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma quadra cadastrada'), findsOneWidget);
      expect(find.byKey(const Key('empty_add_court_button')), findsOneWidget);
      expect(find.text('Cadastrar Primeira Quadra'), findsOneWidget);
    });

    testWidgets('ao clicar em Cadastrar Primeira Quadra, navega para CourtFormPage',
        (tester) async {
      final emptyRepo = InMemoryCourtRepository([]);
      final emptyController = MyCourtsController(
        listMyCourts: ListMyCourts(emptyRepo),
        createCourt: CreateCourt(emptyRepo, imageStorage),
        updateCourt: UpdateCourt(emptyRepo, imageStorage),
        deleteCourt: DeleteCourt(emptyRepo),
      );

      await tester.pumpWidget(buildSubject(customController: emptyController));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('empty_add_court_button')));
      await tester.pumpAndSettle();

      expect(find.text('Nova Quadra'), findsOneWidget);
      expect(find.text('Cadastrar Quadra'), findsOneWidget);
    });

    testWidgets('exibe listagem de quadras e botão Nova Quadra quando há quadras',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Minhas Quadras'), findsOneWidget);
      expect(find.text('2 quadras gerenciadas'), findsOneWidget);
      expect(find.byKey(const Key('add_court_button')), findsOneWidget);

      expect(find.text('Quadra Central de Beach Tennis'), findsOneWidget);
      expect(find.text('Av. Brasil, 500'), findsOneWidget);
      expect(find.text('R\$ 130,00'), findsOneWidget);
      expect(find.text('8h–22h'), findsOneWidget);

      expect(find.text('Arena Society Gol'), findsOneWidget);
      expect(find.text('Rua do Esporte, 100'), findsOneWidget);
      expect(find.text('R\$ 180,00'), findsOneWidget);
      expect(find.text('7h–23h'), findsOneWidget);
    });

    testWidgets('ao clicar em Editar, abre CourtFormPage com os dados da quadra',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final editButton = find.byKey(Key('owner_court_edit_${court1.id}'));
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Editar Quadra'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
      expect(find.text('Quadra Central de Beach Tennis'), findsOneWidget);
    });

    testWidgets('ao clicar em Ver Agenda, invoca callback com a quadra',
        (tester) async {
      Court? clickedCourt;

      await tester.pumpWidget(
        buildSubject(
          onViewCourtAgenda: (court) => clickedCourt = court,
        ),
      );
      await tester.pumpAndSettle();

      final agendaButton = find.byKey(Key('owner_court_agenda_${court1.id}'));
      await tester.ensureVisible(agendaButton);
      await tester.tap(agendaButton);
      await tester.pumpAndSettle();

      expect(clickedCourt, isNotNull);
      expect(clickedCourt?.id, court1.id);
    });

    testWidgets('fluxo de exclusão com confirmação e feedback',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Clica no botão de exclusão da quadra 1
      final deleteButton = find.byKey(Key('owner_court_delete_${court1.id}'));
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confere se o modal de confirmação abriu
      expect(find.text('Excluir Quadra'), findsOneWidget);
      expect(
        find.textContaining('Tem certeza de que deseja excluir a quadra "${court1.name}"?'),
        findsOneWidget,
      );

      // Clica em Cancelar: nada é excluído
      await tester.tap(find.byKey(const Key('delete_court_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Quadra'), findsNothing);
      expect(controller.courts.length, 2);

      // Abre novamente e confirma a exclusão
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_court_confirm_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // SnackBar de feedback
      expect(
        find.text('Quadra "${court1.name}" excluída com sucesso.'),
        findsOneWidget,
      );

      // Apenas 1 quadra restou na lista
      expect(controller.courts.length, 1);
      expect(controller.courts.first.id, court2.id);
      expect(find.text('1 quadra gerenciada'), findsOneWidget);
    });

    testWidgets('exibe mensagem de erro quando o carregamento falha',
        (tester) async {
      final failingRepo = FailingCourtRepository(
        const StorageFailure('Falha ao carregar quadras'),
      );
      final failingCtrl = MyCourtsController(
        listMyCourts: ListMyCourts(failingRepo),
        createCourt: CreateCourt(failingRepo, imageStorage),
        updateCourt: UpdateCourt(failingRepo, imageStorage),
        deleteCourt: DeleteCourt(failingRepo),
      );

      await tester.pumpWidget(buildSubject(customController: failingCtrl));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar quadras'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
