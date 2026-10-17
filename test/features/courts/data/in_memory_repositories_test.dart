import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_booking_repository.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/data/seed/demo_courts.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryCourtRepository', () {
    const repository = InMemoryCourtRepository();

    test('lista o catálogo semeado', () async {
      final result = await repository.listAll();

      expect((result as Ok<List<Court>>).value, hasLength(demoCourts.length));
    });

    test('encontra uma quadra pelo id', () async {
      final result = await repository.findById('pajucara');

      expect((result as Ok<Court>).value.name, 'Quadra Pajuçara');
    });

    test('devolve falha tipada para id inexistente', () async {
      final result = await repository.findById('nao-existe');

      expect((result as Err<Court>).failure, isA<CourtNotFoundFailure>());
    });

    test('a lista devolvida não pode ser alterada por quem recebe', () async {
      final courts = (await repository.listAll() as Ok<List<Court>>).value;

      expect(() => courts.clear(), throwsUnsupportedError);
    });
  });

  group('InMemoryBookingRepository', () {
    late InMemoryBookingRepository repository;

    Booking reserva(String id, DateTime start, {String user = 'u1'}) => Booking(
          id: id,
          courtId: 'quadra-1',
          userId: user,
          start: start,
        );

    setUp(() => repository = InMemoryBookingRepository());

    test('guarda e devolve as reservas do dia da quadra', () async {
      await repository.create(reserva('a', DateTime(2026, 9, 28, 19)));
      await repository.create(reserva('b', DateTime(2026, 9, 29, 19)));

      final result = await repository.forCourtOn(
        courtId: 'quadra-1',
        day: DateTime(2026, 9, 28),
      );

      expect((result as Ok<List<Booking>>).value.map((b) => b.id), ['a']);
    });

    test('separa as reservas por usuário e ordena por horário', () async {
      await repository.create(reserva('tarde', DateTime(2026, 9, 28, 20)));
      await repository.create(reserva('cedo', DateTime(2026, 9, 28, 8)));
      await repository.create(
        reserva('de-outro', DateTime(2026, 9, 28, 9), user: 'u2'),
      );

      final result = await repository.ofUser('u1');

      expect(
        (result as Ok<List<Booking>>).value.map((b) => b.id),
        ['cedo', 'tarde'],
      );
    });
  });
}
