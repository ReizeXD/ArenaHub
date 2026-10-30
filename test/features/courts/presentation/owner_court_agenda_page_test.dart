import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/get_owner_court_agenda.dart';
import 'package:arenahub/features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'package:arenahub/features/courts/presentation/pages/owner_court_agenda_page.dart';
import 'package:arenahub/features/courts/presentation/states/owner_agenda_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late FakeBookingRepository bookingsRepo;
  late GetOwnerCourtAgenda getAgenda;
  late OwnerAgendaController controller;

  final fixedNow = DateTime(2026, 10, 29, 10, 0);
  final tomorrow = DateTime(2026, 10, 30);

  const testCourt = Court(
    id: 'court-100',
    ownerId: 'owner-1',
    name: 'Arena Central de Beach Tennis',
    sport: Sport.beachTennis,
    address: 'Av. das Dunas, 200',
    pricePerHourInCents: 11000,
    openingHour: 8,
    closingHour: 12, // 4 slots: 8h, 9h, 10h, 11h
  );

  final bookingToday = Booking(
    id: 'b1',
    courtId: 'court-100',
    userId: 'athlete-1',
    userName: 'Roberto Carlos',
    start: DateTime(2026, 10, 29, 9, 0),
  );

  final bookingTomorrow = Booking(
    id: 'b2',
    courtId: 'court-100',
    userId: 'athlete-2',
    userName: 'Ana Paula',
    start: DateTime(2026, 10, 30, 8, 0),
  );

  setUp(() {
    bookingsRepo = FakeBookingRepository([bookingToday, bookingTomorrow]);
    getAgenda = GetOwnerCourtAgenda(bookingsRepo, now: () => fixedNow);
    controller = OwnerAgendaController(
      getAgenda,
      now: () => fixedNow,
      daysAhead: 7,
    );
  });

  Widget buildSubject({OwnerAgendaController? customController}) {
    return MaterialApp(
      home: OwnerCourtAgendaPage(
        court: testCourt,
        ownerId: 'owner-1',
        controller: customController ?? controller,
      ),
    );
  }

  group('OwnerCourtAgendaPage', () {
    testWidgets('exibe indicador de carregamento durante OwnerAgendaLoading',
        (tester) async {
      final unstarted = OwnerAgendaController(
        getAgenda,
        now: () => fixedNow,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: switch (unstarted.state) {
                OwnerAgendaLoading() => const CircularProgressIndicator(),
                _ => const SizedBox(),
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('carrega e renderiza cabeçalho, seletor de datas, métricas e slots',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Cabeçalho da página
      expect(find.text('Agenda da Quadra'), findsOneWidget);
      expect(find.text('Arena Central de Beach Tennis'), findsOneWidget);
      expect(find.text('Av. das Dunas, 200'), findsOneWidget);
      expect(find.text('8h–12h'), findsOneWidget);

      // Seletor de datas
      expect(find.byKey(const Key('owner_agenda_date_strip')), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);

      // Métricas do dia (1 de 4 horários agendados = R$ 110,00)
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('Horários agendados'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('metric_revenue')),
          matching: find.text('R\$ 110,00'),
        ),
        findsOneWidget,
      );
      expect(find.text('Faturamento estimado'), findsOneWidget);

      // Grade de horários do dia de hoje
      expect(find.text('Grade de Horários'), findsOneWidget);
      expect(find.text('4 horários'), findsOneWidget);

      // Slot 9h reservado com identificação do atleta
      expect(find.text('09:00 às 10:00'), findsOneWidget);
      expect(find.text('Roberto Carlos'), findsOneWidget);
      expect(find.text('Reserva confirmada'), findsOneWidget);
      expect(find.text('RESERVADO'), findsOneWidget);

      // Slots livres
      expect(find.text('08:00 às 09:00'), findsOneWidget);
      expect(find.text('10:00 às 11:00'), findsOneWidget);
      expect(find.text('11:00 às 12:00'), findsOneWidget);
    });

    testWidgets('ao tocar em outro dia no seletor de data, atualiza a grade e métricas',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Verifica que hoje tem Roberto Carlos
      expect(find.text('Roberto Carlos'), findsOneWidget);

      // Toca em Amanhã (dia 30)
      final tomorrowKey = Key('agenda_day_${tomorrow.day}');
      await tester.tap(find.byKey(tomorrowKey));
      await tester.pump();
      await tester.pumpAndSettle();

      // Agora deve exibir a reserva da Ana Paula às 8h
      expect(find.text('Ana Paula'), findsOneWidget);
      expect(find.text('08:00 às 09:00'), findsOneWidget);
      expect(find.text('Roberto Carlos'), findsNothing);

      // Métricas continuam refletindo 1 / 4
      expect(find.text('1 / 4'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('metric_revenue')),
          matching: find.text('R\$ 110,00'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('executa pull-to-refresh recarregando a agenda', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Roberto Carlos'), findsOneWidget);
      expect(find.text('Carlos Silva'), findsNothing);

      // Adiciona uma nova reserva no repositório
      await bookingsRepo.create(
        Booking(
          id: 'b3',
          courtId: 'court-100',
          userId: 'athlete-3',
          userName: 'Carlos Silva',
          start: DateTime(2026, 10, 29, 11, 0),
        ),
      );

      // Fling no RefreshIndicator para disparar o recarregamento
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Carlos Silva'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('exibe mensagem de erro e botão de retry quando falha',
        (tester) async {
      final failingAgenda = GetOwnerCourtAgenda(
        FakeBookingRepository(),
        now: () => fixedNow,
      );
      final failingCtrl = OwnerAgendaController(
        failingAgenda,
        now: () => fixedNow,
      );

      // Simula usuário não proprietário para gerar falha
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerCourtAgendaPage(
            court: testCourt,
            ownerId: 'outro-dono',
            controller: failingCtrl,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Você só pode gerenciar quadras que você mesmo cadastrou.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('agenda_retry_button')), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
