import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/get_owner_court_agenda.dart';
import 'package:arenahub/features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'package:arenahub/features/courts/presentation/states/owner_agenda_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  late FakeBookingRepository bookingsRepo;
  late GetOwnerCourtAgenda getAgenda;
  late OwnerAgendaController controller;

  final fixedNow = DateTime(2026, 10, 29, 10, 0);
  final today = DateTime(2026, 10, 29);
  final tomorrow = DateTime(2026, 10, 30);

  const testCourt = Court(
    id: 'court-100',
    ownerId: 'owner-1',
    name: 'Arena Central',
    sport: Sport.beachTennis,
    address: 'Av. Principal, 10',
    pricePerHourInCents: 12000,
    openingHour: 8,
    closingHour: 12, // 4 horários: 08:00, 09:00, 10:00, 11:00
  );

  final bookingToday1 = Booking(
    id: 'b1',
    courtId: 'court-100',
    userId: 'player-1',
    userName: 'Carlos Silva',
    start: DateTime(2026, 10, 29, 9, 0),
  );

  final bookingToday2 = Booking(
    id: 'b2',
    courtId: 'court-100',
    userId: 'player-2',
    userName: 'Mariana Costa',
    start: DateTime(2026, 10, 29, 11, 0),
  );

  setUp(() {
    bookingsRepo = FakeBookingRepository([bookingToday1, bookingToday2]);
    getAgenda = GetOwnerCourtAgenda(bookingsRepo, now: () => fixedNow);
    controller = OwnerAgendaController(
      getAgenda,
      now: () => fixedNow,
      daysAhead: 7,
    );
  });

  group('OwnerAgendaController & OwnerAgendaState', () {
    test('estado inicial começa com OwnerAgendaLoading e métricas zeradas', () {
      expect(controller.state, isA<OwnerAgendaLoading>());
      expect(controller.slots, isEmpty);
      expect(controller.bookedCount, 0);
      expect(controller.totalSlots, 0);
      expect(controller.revenueInCents, 0);
      expect(controller.formattedRevenue, 'R\$ 0,00');
      expect(controller.availableDays.length, 7);
      expect(controller.availableDays.first, today);
    });

    test('load() com sucesso carrega slots e calcula métricas corretamente', () async {
      await controller.load(court: testCourt, day: today, userId: 'owner-1');

      expect(controller.state, isA<OwnerAgendaLoaded>());
      final state = controller.state as OwnerAgendaLoaded;

      expect(state.court.id, testCourt.id);
      expect(state.selectedDay, today);
      expect(state.slots.length, 4);

      // Métricas
      expect(state.totalSlots, 4);
      expect(state.bookedCount, 2);
      expect(state.availableCount, 2);
      expect(state.revenueInCents, 24000); // 2 * 12000
      expect(state.formattedRevenue, 'R\$ 240,00');

      // Delegação de getters no controller
      expect(controller.bookedCount, 2);
      expect(controller.totalSlots, 4);
      expect(controller.revenueInCents, 24000);
      expect(controller.formattedRevenue, 'R\$ 240,00');

      // Detalhes dos slots e identificação dos atletas
      final slot8 = state.slots[0];
      expect(slot8.start.hour, 8);
      expect(slot8.isBooked, isFalse);

      final slot9 = state.slots[1];
      expect(slot9.start.hour, 9);
      expect(slot9.isBooked, isTrue);
      expect(slot9.booking?.userName, 'Carlos Silva');

      final slot10 = state.slots[2];
      expect(slot10.start.hour, 10);
      expect(slot10.isBooked, isFalse);

      final slot11 = state.slots[3];
      expect(slot11.start.hour, 11);
      expect(slot11.isBooked, isTrue);
      expect(slot11.booking?.userName, 'Mariana Costa');
    });

    test('selectDay() troca a data ativa e atualiza a lista de slots', () async {
      await controller.load(court: testCourt, day: today, userId: 'owner-1');
      expect(controller.bookedCount, 2);

      // Troca para amanhã (sem reservas cadastradas)
      await controller.selectDay(tomorrow);

      expect(controller.state, isA<OwnerAgendaLoaded>());
      final state = controller.state as OwnerAgendaLoaded;
      expect(state.selectedDay, tomorrow);
      expect(state.bookedCount, 0);
      expect(state.availableCount, 4);
      expect(state.revenueInCents, 0);
      expect(state.formattedRevenue, 'R\$ 0,00');
    });

    test('selectDay() no mesmo dia já carregado não dispara recarga desnecessária', () async {
      await controller.load(court: testCourt, day: today, userId: 'owner-1');

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.selectDay(today);

      expect(notifications, 0);
    });

    test('reload() recarrega os dados do dia selecionado', () async {
      await controller.load(court: testCourt, day: today, userId: 'owner-1');

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.reload();

      expect(notifications, 2); // Loading -> Loaded
      expect(controller.state, isA<OwnerAgendaLoaded>());
    });

    test('load() falha quando o usuário não é o dono da quadra', () async {
      await controller.load(
        court: testCourt,
        day: today,
        userId: 'intruder-id',
      );

      expect(controller.state, isA<OwnerAgendaFailed>());
      final state = controller.state as OwnerAgendaFailed;
      expect(state.failure, isA<UnauthorizedCourtActionFailure>());
      expect(controller.slots, isEmpty);
      expect(controller.bookedCount, 0);
      expect(controller.revenueInCents, 0);
    });
  });
}
