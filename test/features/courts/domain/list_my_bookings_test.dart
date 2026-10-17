import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/booking_with_court.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_bookings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  final agora = DateTime(2026, 9, 28, 12);

  Booking reserva(String id, DateTime start, {String user = 'u1', String court = 'pajucara'}) =>
      Booking(id: id, courtId: court, userId: user, start: start);

  List<BookingWithCourt> itemsOf(Result<List<BookingWithCourt>> r) =>
      (r as Ok<List<BookingWithCourt>>).value;

  test('junta cada reserva com a quadra correspondente', () async {
    final bookings = FakeBookingRepository([
      reserva('a', DateTime(2026, 9, 29, 19)),
    ]);
    final usecase = ListMyBookings(
      bookings,
      const InMemoryCourtRepository(),
      now: () => agora,
    );

    final items = itemsOf(await usecase('u1'));

    // O documento da reserva guarda só o courtId — o nome vem da junção.
    expect(items, hasLength(1));
    expect(items.first.court.name, 'Quadra Pajuçara');
    expect(items.first.formattedDate, '29/09');
    expect(items.first.formattedTime, '19:00 às 20:00');
  });

  test('marca como passada a reserva que já terminou', () async {
    final bookings = FakeBookingRepository([
      reserva('passada', DateTime(2026, 9, 28, 8)),
      reserva('futura', DateTime(2026, 9, 28, 20)),
    ]);
    final usecase = ListMyBookings(
      bookings,
      const InMemoryCourtRepository(),
      now: () => agora,
    );

    final items = itemsOf(await usecase('u1'));

    expect(items.map((i) => i.isPast), [true, false]);
  });

  test('ordena da mais próxima para a mais distante', () async {
    final bookings = FakeBookingRepository([
      reserva('depois', DateTime(2026, 9, 30, 10)),
      reserva('antes', DateTime(2026, 9, 29, 10)),
    ]);
    final usecase = ListMyBookings(
      bookings,
      const InMemoryCourtRepository(),
      now: () => agora,
    );

    expect(
      itemsOf(await usecase('u1')).map((i) => i.booking.id),
      ['antes', 'depois'],
    );
  });

  test('não devolve reserva de outro usuário', () async {
    final bookings = FakeBookingRepository([
      reserva('minha', DateTime(2026, 9, 29, 10)),
      reserva('alheia', DateTime(2026, 9, 29, 11), user: 'u2'),
    ]);
    final usecase = ListMyBookings(
      bookings,
      const InMemoryCourtRepository(),
      now: () => agora,
    );

    expect(itemsOf(await usecase('u1')).map((i) => i.booking.id), ['minha']);
  });

  test('descarta em silêncio reserva de quadra que não existe mais', () async {
    // Sem chave estrangeira, o banco não impede apagar uma quadra reservada.
    final bookings = FakeBookingRepository([
      reserva('orfa', DateTime(2026, 9, 29, 10), court: 'quadra-apagada'),
      reserva('boa', DateTime(2026, 9, 29, 11)),
    ]);
    final usecase = ListMyBookings(
      bookings,
      const InMemoryCourtRepository(),
      now: () => agora,
    );

    expect(itemsOf(await usecase('u1')).map((i) => i.booking.id), ['boa']);
  });

  test('propaga falha do catálogo em vez de devolver lista vazia', () async {
    final usecase = ListMyBookings(
      FakeBookingRepository([reserva('a', DateTime(2026, 9, 29, 10))]),
      const FailingCourtRepository(),
      now: () => agora,
    );

    final result = await usecase('u1');

    expect(
      (result as Err<List<BookingWithCourt>>).failure,
      isA<StorageFailure>(),
    );
  });
}
