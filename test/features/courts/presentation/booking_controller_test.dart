import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/presentation/states/agenda_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  final agora = DateTime(2026, 9, 28, 9, 30);

  test('abre no dia de hoje, sem a hora', () async {
    final controller = bookingControllerWith(now: () => agora);

    await controller.open(testCourt);

    expect(controller.selectedDay, DateTime(2026, 9, 28));
    expect(controller.state, isA<AgendaLoaded>());
  });

  test('oferece uma semana de dias a partir de hoje', () async {
    final controller = bookingControllerWith(now: () => agora);

    await controller.open(testCourt);

    expect(controller.availableDays, hasLength(7));
    expect(controller.availableDays.first, DateTime(2026, 9, 28));
    expect(controller.availableDays.last, DateTime(2026, 10, 4));
  });

  test('trocar de dia recarrega a agenda', () async {
    final controller = bookingControllerWith(now: () => agora);
    await controller.open(testCourt);

    await controller.selectDay(DateTime(2026, 9, 29));

    expect(controller.selectedDay, DateTime(2026, 9, 29));
    final slots = (controller.state as AgendaLoaded).slots;
    // Amanhã nenhum horário passou ainda.
    expect(slots.every((s) => s.isAvailable), isTrue);
  });

  test('reservar devolve null e marca o horário como ocupado', () async {
    final controller = bookingControllerWith(now: () => agora);
    await controller.open(testCourt);
    await controller.selectDay(DateTime(2026, 9, 29));

    final livre = (controller.state as AgendaLoaded).slots.first;
    final failure = await controller.book(slot: livre, userId: 'u1');

    expect(failure, isNull);
    final depois = (controller.state as AgendaLoaded).slots.first;
    expect(depois.isAvailable, isFalse, reason: 'a agenda foi recarregada');
  });

  test('devolve a falha quando o horário já foi tomado', () async {
    final bookings = FakeBookingRepository([
      Booking(
        id: 'r',
        courtId: testCourt.id,
        userId: 'outro',
        start: DateTime(2026, 9, 29, 8),
      ),
    ]);
    final controller = bookingControllerWith(
      bookings: bookings,
      now: () => agora,
    );
    await controller.open(testCourt);
    await controller.selectDay(DateTime(2026, 9, 29));

    final ocupado = (controller.state as AgendaLoaded).slots.first;
    final failure = await controller.book(slot: ocupado, userId: 'u1');

    expect(failure, isA<SlotUnavailableFailure>());
  });

  test('não fica preso em "reservando" depois de falhar', () async {
    final controller = bookingControllerWith(now: () => agora);
    await controller.open(testCourt);

    // Primeiro horário de hoje já passou (são 9h30).
    final passado = (controller.state as AgendaLoaded).slots.first;
    await controller.book(slot: passado, userId: 'u1');

    expect(controller.isBooking, isFalse);
  });
}
