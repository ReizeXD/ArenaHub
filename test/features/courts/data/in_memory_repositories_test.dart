import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_booking_repository.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/data/seed/demo_courts.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryCourtRepository', () {
    late InMemoryCourtRepository repository;

    setUp(() {
      repository = InMemoryCourtRepository();
    });

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

    test('nextIdentity gera identificador único não vazio', () {
      final id1 = repository.nextIdentity();
      final id2 = repository.nextIdentity();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(id2));
    });

    test('listByOwner filtra apenas quadras do proprietário informado', () async {
      const q1 = Court(
        id: 'q1',
        ownerId: 'dono-a',
        name: 'Quadra A1',
        sport: Sport.futsal,
        address: 'Rua 1',
        pricePerHourInCents: 10000,
      );
      const q2 = Court(
        id: 'q2',
        ownerId: 'dono-a',
        name: 'Quadra A2',
        sport: Sport.beachTennis,
        address: 'Rua 2',
        pricePerHourInCents: 12000,
      );
      const q3 = Court(
        id: 'q3',
        ownerId: 'dono-b',
        name: 'Quadra B1',
        sport: Sport.society,
        address: 'Rua 3',
        pricePerHourInCents: 15000,
      );

      final repo = InMemoryCourtRepository([q1, q2, q3]);

      final donoA = (await repo.listByOwner('dono-a') as Ok<List<Court>>).value;
      expect(donoA.map((c) => c.id), ['q1', 'q2']);

      final donoB = (await repo.listByOwner('dono-b') as Ok<List<Court>>).value;
      expect(donoB.map((c) => c.id), ['q3']);

      final semQuadras =
          (await repo.listByOwner('outro') as Ok<List<Court>>).value;
      expect(semQuadras, isEmpty);
    });

    test('create adiciona a quadra ao catálogo', () async {
      const nova = Court(
        id: 'nova-1',
        ownerId: 'dono-1',
        name: 'Nova Arena',
        sport: Sport.futsal,
        address: 'Av Central, 50',
        pricePerHourInCents: 8000,
      );

      final createResult = await repository.create(nova);
      expect(createResult, isA<Ok<Court>>());
      expect((createResult as Ok<Court>).value, nova);

      final findResult = await repository.findById('nova-1');
      expect((findResult as Ok<Court>).value.name, 'Nova Arena');
    });

    test('update altera os dados da quadra existente', () async {
      final existente =
          (await repository.findById('pajucara') as Ok<Court>).value;
      final alterada = existente.copyWith(
        name: 'Pajuçara VIP',
        pricePerHourInCents: 20000,
      );

      final updateResult = await repository.update(alterada);
      expect(updateResult, isA<Ok<Court>>());

      final findResult =
          (await repository.findById('pajucara') as Ok<Court>).value;
      expect(findResult.name, 'Pajuçara VIP');
      expect(findResult.pricePerHourInCents, 20000);
    });

    test('update devolve CourtNotFoundFailure se a quadra não existir', () async {
      const inexistente = Court(
        id: 'fantasma',
        ownerId: 'dono-1',
        name: 'Inexistente',
        sport: Sport.futsal,
        address: 'Rua 0',
        pricePerHourInCents: 5000,
      );

      final result = await repository.update(inexistente);
      expect((result as Err<Court>).failure, isA<CourtNotFoundFailure>());
    });

    test('delete remove a quadra do catálogo', () async {
      final deleteResult = await repository.delete('pajucara');
      expect(deleteResult, isA<Ok<void>>());

      final findResult = await repository.findById('pajucara');
      expect((findResult as Err<Court>).failure, isA<CourtNotFoundFailure>());
    });

    test('delete de id inexistente não estoura erro', () async {
      final deleteResult = await repository.delete('inexistente');
      expect(deleteResult, isA<Ok<void>>());
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
