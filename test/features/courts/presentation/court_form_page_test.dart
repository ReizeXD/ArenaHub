import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/create_court.dart';
import 'package:arenahub/features/courts/domain/usecases/delete_court.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/update_court.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/pages/court_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late InMemoryCourtRepository repository;
  late FakeCourtImageStorage imageStorage;
  late MyCourtsController controller;

  const ownerId = 'owner-123';

  const existingCourt = Court(
    id: 'court-1',
    ownerId: ownerId,
    name: 'Arena Central de Futsal',
    sport: Sport.futsal,
    address: 'Av. Paulista, 1000',
    pricePerHourInCents: 12000,
    openingHour: 9,
    closingHour: 23,
  );

  setUp(() {
    repository = InMemoryCourtRepository([existingCourt]);
    imageStorage = FakeCourtImageStorage();
    controller = MyCourtsController(
      listMyCourts: ListMyCourts(repository),
      createCourt: CreateCourt(repository, imageStorage),
      updateCourt: UpdateCourt(repository, imageStorage),
      deleteCourt: DeleteCourt(repository),
    );
  });

  Widget buildSubject({Court? courtToEdit, MyCourtsController? customCtrl}) {
    return MaterialApp(
      home: CourtFormPage(
        ownerId: ownerId,
        courtToEdit: courtToEdit,
        controller: customCtrl ?? controller,
      ),
    );
  }

  group('CourtFormPage — Modo Criação', () {
    testWidgets('exibe título Nova Quadra e botão Cadastrar Quadra',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Nova Quadra'), findsOneWidget);
      expect(find.text('Cadastrar Quadra'), findsOneWidget);
      expect(find.byKey(const Key('court_name_field')), findsOneWidget);
      expect(find.byKey(const Key('court_address_field')), findsOneWidget);
      expect(find.byKey(const Key('court_price_field')), findsOneWidget);
      expect(find.byKey(const Key('court_sport_field')), findsOneWidget);
      expect(find.byKey(const Key('court_opening_hour_field')), findsOneWidget);
      expect(find.byKey(const Key('court_closing_hour_field')), findsOneWidget);
    });

    testWidgets('valida campos obrigatórios quando submetido vazio',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome da quadra'), findsOneWidget);
      expect(find.text('Informe o endereço da quadra'), findsOneWidget);
      expect(find.text('Informe o preço por hora'), findsOneWidget);
    });

    testWidgets('valida preço inválido ou menor ou igual a zero',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('court_name_field')),
        'Quadra Teste',
      );
      await tester.enterText(
        find.byKey(const Key('court_address_field')),
        'Rua Teste, 10',
      );
      await tester.enterText(
        find.byKey(const Key('court_price_field')),
        '0',
      );

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Informe um preço válido maior que zero'),
        findsOneWidget,
      );
    });

    testWidgets('cadastra nova quadra com sucesso e emite feedback',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('court_name_field')),
        'Arena Nova de Beach Tennis',
      );
      await tester.enterText(
        find.byKey(const Key('court_address_field')),
        'Av. das Américas, 300',
      );
      await tester.enterText(
        find.byKey(const Key('court_price_field')),
        '150,00',
      );

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Quadra cadastrada com sucesso!'), findsOneWidget);

      final listResult = await repository.listByOwner(ownerId);
      final list = (listResult as Ok<List<Court>>).value;
      expect(list.length, 2);
      expect(
        list.any((c) => c.name == 'Arena Nova de Beach Tennis' && c.pricePerHourInCents == 15000),
        isTrue,
      );
    });
  });

  group('CourtFormPage — Modo Edição', () {
    testWidgets('preenche campos com dados da quadra existente',
        (tester) async {
      await tester.pumpWidget(buildSubject(courtToEdit: existingCourt));

      expect(find.text('Editar Quadra'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
      expect(find.text('Arena Central de Futsal'), findsOneWidget);
      expect(find.text('Av. Paulista, 1000'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('atualiza quadra com sucesso e emite feedback',
        (tester) async {
      await tester.pumpWidget(buildSubject(courtToEdit: existingCourt));

      await tester.enterText(
        find.byKey(const Key('court_name_field')),
        'Arena Central Atualizada',
      );
      await tester.enterText(
        find.byKey(const Key('court_price_field')),
        '140,50',
      );

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Quadra atualizada com sucesso!'), findsOneWidget);

      final found = ((await repository.findById(existingCourt.id)) as Ok<Court>).value;
      expect(found.name, 'Arena Central Atualizada');
      expect(found.pricePerHourInCents, 14050);
    });

    testWidgets('exibe mensagem de erro quando o controlador falha',
        (tester) async {
      final failingRepo = FailingCourtRepository(
        const StorageFailure('Erro interno no banco'),
      );
      final failingCtrl = MyCourtsController(
        listMyCourts: ListMyCourts(failingRepo),
        createCourt: CreateCourt(failingRepo, imageStorage),
        updateCourt: UpdateCourt(failingRepo, imageStorage),
        deleteCourt: DeleteCourt(failingRepo),
      );

      await tester.pumpWidget(
        buildSubject(
          courtToEdit: existingCourt,
          customCtrl: failingCtrl,
        ),
      );

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Erro interno no banco'), findsOneWidget);
    });
  });

  group('CourtFormPage — Validação de Horários e Preço', () {
    testWidgets('valida horários quando fechamento <= abertura',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          courtToEdit: existingCourt.copyWith(openingHour: 20, closingHour: 10),
        ),
      );

      final submitFinder = find.byKey(const Key('court_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('O horário de fechamento deve ser posterior ao de abertura.'),
        findsOneWidget,
      );
    });

    test('parsePriceInCents faz parsing de vários formatos monetários', () {
      expect(CourtFormPage.parsePriceInCents('120'), 12000);
      expect(CourtFormPage.parsePriceInCents('120.00'), 12000);
      expect(CourtFormPage.parsePriceInCents('120,50'), 12050);
      expect(CourtFormPage.parsePriceInCents('R\$ 1.250,00'), 125000);
      expect(CourtFormPage.parsePriceInCents('0'), isNull);
      expect(CourtFormPage.parsePriceInCents('-50'), isNull);
      expect(CourtFormPage.parsePriceInCents(''), isNull);
      expect(CourtFormPage.parsePriceInCents('abc'), isNull);
    });
  });
}
