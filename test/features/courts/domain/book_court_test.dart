import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/usecases/book_court.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  final agora = DateTime(2026, 9, 28, 9, 30);

  late FakeBookingRepository repository;
  late BookCourt bookCourt;

  setUp(() {
    repository = FakeBookingRepository();
    bookCourt = BookCourt(
      repository,
      now: () => agora,
      idGenerator: () => 'reserva-1',
    );
  });

  Future<Result<Booking>> reservar(DateTime start) =>
      bookCourt(court: testCourt, userId: 'usuario-1', start: start);

  test('reserva um horário livre', () async {
    final result = await reservar(DateTime(2026, 9, 28, 11));

    expect(result, isA<Ok<Booking>>());
    expect((result as Ok<Booking>).value.userId, 'usuario-1');
    expect(repository.createCalls, 1);
  });

  test('recusa horário que já passou', () async {
    final result = await reservar(DateTime(2026, 9, 28, 8));

    expect((result as Err<Booking>).failure, isA<SlotInThePastFailure>());
    expect(repository.createCalls, 0, reason: 'valida antes de escrever');
  });

  test('recusa horário fora do funcionamento da quadra', () async {
    // A quadra de teste fecha às 12h.
    final result = await reservar(DateTime(2026, 9, 29, 15));

    expect(
      (result as Err<Booking>).failure,
      isA<OutsideOperatingHoursFailure>(),
    );
    expect(repository.createCalls, 0);
  });

  test('recusa horário que outra pessoa já reservou', () async {
    await reservar(DateTime(2026, 9, 29, 10));

    final segunda = await BookCourt(
      repository,
      now: () => agora,
      idGenerator: () => 'reserva-2',
    )(court: testCourt, userId: 'usuario-2', start: DateTime(2026, 9, 29, 10));

    expect((segunda as Err<Booking>).failure, isA<SlotUnavailableFailure>());
    expect(repository.createCalls, 1, reason: 'a segunda não foi gravada');
  });

  test('reconfere a agenda antes de gravar', () async {
    // Entre a tela carregar e o toque no botão, outra pessoa pode reservar.
    // Por isso a checagem acontece no caso de uso, não só na interface.
    repository = FakeBookingRepository([
      Booking(
        id: 'r-concorrente',
        courtId: testCourt.id,
        userId: 'outro',
        start: DateTime(2026, 9, 29, 11),
      ),
    ]);

    final result = await BookCourt(repository, now: () => agora)(
      court: testCourt,
      userId: 'usuario-1',
      start: DateTime(2026, 9, 29, 11),
    );

    expect((result as Err<Booking>).failure, isA<SlotUnavailableFailure>());
  });
}
