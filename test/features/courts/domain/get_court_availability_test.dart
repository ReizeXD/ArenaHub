import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/time_slot.dart';
import 'package:arenahub/features/courts/domain/usecases/get_court_availability.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  // "Agora" fixo: o teste não pode depender da hora em que roda.
  final agora = DateTime(2026, 9, 28, 9, 30);
  final hoje = DateTime(2026, 9, 28);
  final amanha = DateTime(2026, 9, 29);

  List<TimeSlot> slotsOf(Result<List<TimeSlot>> result) =>
      (result as Ok<List<TimeSlot>>).value;

  test('gera um horário por hora de funcionamento', () async {
    final usecase = GetCourtAvailability(FakeBookingRepository(), now: () => agora);

    final slots = slotsOf(await usecase(court: testCourt, day: amanha));

    // Abre 8h, fecha 12h: 8, 9, 10 e 11.
    expect(slots.map((s) => s.label), ['08:00', '09:00', '10:00', '11:00']);
  });

  test('marca como indisponível o horário que já passou hoje', () async {
    final usecase = GetCourtAvailability(FakeBookingRepository(), now: () => agora);

    final slots = slotsOf(await usecase(court: testCourt, day: hoje));

    // São 9h30: 8h e 9h já passaram.
    expect(slots[0].isAvailable, isFalse, reason: '08:00 já passou');
    expect(slots[1].isAvailable, isFalse, reason: '09:00 já passou');
    expect(slots[2].isAvailable, isTrue, reason: '10:00 ainda dá');
  });

  test('marca como indisponível o horário já reservado', () async {
    final repository = FakeBookingRepository([
      Booking(
        id: 'r1',
        courtId: testCourt.id,
        userId: 'outro-usuario',
        start: DateTime(2026, 9, 29, 10),
      ),
    ]);
    final usecase = GetCourtAvailability(repository, now: () => agora);

    final slots = slotsOf(await usecase(court: testCourt, day: amanha));

    expect(slots[2].label, '10:00');
    expect(slots[2].isAvailable, isFalse);
    expect(slots[3].isAvailable, isTrue, reason: 'as outras seguem livres');
  });

  test('reserva de outro dia não bloqueia o dia consultado', () async {
    final repository = FakeBookingRepository([
      Booking(
        id: 'r1',
        courtId: testCourt.id,
        userId: 'outro-usuario',
        start: DateTime(2026, 9, 30, 10),
      ),
    ]);
    final usecase = GetCourtAvailability(repository, now: () => agora);

    final slots = slotsOf(await usecase(court: testCourt, day: amanha));

    expect(slots.every((s) => s.isAvailable), isTrue);
  });
}
