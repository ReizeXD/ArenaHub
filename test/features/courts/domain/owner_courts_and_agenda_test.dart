import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/owner_slot_info.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/usecases/get_owner_court_agenda.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_courts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  final agora = DateTime(2026, 9, 28, 14, 30);
  final hoje = DateTime(2026, 9, 28);

  const quadraDono1 = Court(
    id: 'quadra-d1',
    ownerId: 'dono-1',
    name: 'Arena do Dono 1',
    sport: Sport.society,
    address: 'Rua das Palmeiras, 10',
    pricePerHourInCents: 12000,
    openingHour: 8,
    closingHour: 12,
  );

  const quadraDono2 = Court(
    id: 'quadra-d2',
    ownerId: 'dono-2',
    name: 'Arena do Dono 2',
    sport: Sport.beachTennis,
    address: 'Av Beira Mar, 50',
    pricePerHourInCents: 8000,
    openingHour: 7,
    closingHour: 20,
  );

  group('ListMyCourts', () {
    test('lista apenas as quadras pertencentes ao dono solicitado', () async {
      final repository = InMemoryCourtRepository([quadraDono1, quadraDono2]);
      final listMyCourts = ListMyCourts(repository);

      final result = await listMyCourts('dono-1');

      expect(result, isA<Ok<List<Court>>>());
      final courts = (result as Ok<List<Court>>).value;
      expect(courts, hasLength(1));
      expect(courts.first.id, 'quadra-d1');
      expect(courts.first.ownerId, 'dono-1');
    });

    test('devolve lista vazia quando o dono não possui quadras', () async {
      final repository = InMemoryCourtRepository([quadraDono1]);
      final listMyCourts = ListMyCourts(repository);

      final result = await listMyCourts('dono-sem-quadras');

      expect(result, isA<Ok<List<Court>>>());
      expect((result as Ok<List<Court>>).value, isEmpty);
    });
  });

  group('GetOwnerCourtAgenda', () {
    test('monta a grade horária com slots livres e ocupados com dados do atleta', () async {
      final reservaDas10 = Booking(
        id: Booking.slotId(courtId: quadraDono1.id, start: DateTime(2026, 9, 28, 10)),
        courtId: quadraDono1.id,
        userId: 'atleta-123',
        userName: 'Gabriel Jesus',
        start: DateTime(2026, 9, 28, 10),
      );

      final bookingRepo = FakeBookingRepository([reservaDas10]);
      final getOwnerAgenda = GetOwnerCourtAgenda(bookingRepo, now: () => agora);

      final result = await getOwnerAgenda(
        court: quadraDono1,
        day: hoje,
        userId: 'dono-1',
      );

      expect(result, isA<Ok<List<OwnerSlotInfo>>>());
      final slots = (result as Ok<List<OwnerSlotInfo>>).value;

      // Das 8h às 12h = 4 slots: 8h, 9h, 10h, 11h
      expect(slots, hasLength(4));
      expect(slots.map((s) => s.label).toList(), ['08:00', '09:00', '10:00', '11:00']);

      // 08:00 -> livre, no passado (< 14:30)
      expect(slots[0].isBooked, isFalse);
      expect(slots[0].isPast, isTrue);
      expect(slots[0].booking, isNull);

      // 10:00 -> ocupado pelo Gabriel Jesus, no passado (< 14:30)
      expect(slots[2].isBooked, isTrue);
      expect(slots[2].isPast, isTrue);
      expect(slots[2].booking?.userName, 'Gabriel Jesus');
      expect(slots[2].booking?.userId, 'atleta-123');

      // 11:00 -> livre, no passado (< 14:30)
      expect(slots[3].isBooked, isFalse);
    });

    test('marca isPast = false para horários no futuro', () async {
      final amanha = DateTime(2026, 9, 29);
      final bookingRepo = FakeBookingRepository([]);
      final getOwnerAgenda = GetOwnerCourtAgenda(bookingRepo, now: () => agora);

      final result = await getOwnerAgenda(court: quadraDono1, day: amanha);

      expect(result, isA<Ok<List<OwnerSlotInfo>>>());
      final slots = (result as Ok<List<OwnerSlotInfo>>).value;
      expect(slots.every((s) => !s.isPast), isTrue);
      expect(slots.every((s) => !s.isBooked), isTrue);
    });

    test('recusa quando o userId não for o proprietário da quadra', () async {
      final bookingRepo = FakeBookingRepository([]);
      final getOwnerAgenda = GetOwnerCourtAgenda(bookingRepo, now: () => agora);

      final result = await getOwnerAgenda(
        court: quadraDono1,
        day: hoje,
        userId: 'invasor-nao-dono',
      );

      expect((result as Err<List<OwnerSlotInfo>>).failure, isA<UnauthorizedCourtActionFailure>());
    });
  });
}
