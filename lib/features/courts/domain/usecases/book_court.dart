import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../entities/booking.dart';
import '../entities/court.dart';
import '../repositories/booking_repository.dart';

/// Caso de uso: reservar uma hora numa quadra.
///
/// Valida antes de escrever: horário no passado, fora do funcionamento ou já
/// ocupado são recusados aqui, com falha tipada. O repositório só é chamado
/// quando a reserva é legítima.
class BookCourt {
  const BookCourt(this._bookings, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final BookingRepository _bookings;
  final DateTime Function() _now;

  Future<Result<Booking>> call({
    required Court court,
    required String userId,
    required DateTime start,
  }) async {
    if (start.isBefore(_now())) {
      return const Err(SlotInThePastFailure());
    }
    if (start.hour < court.openingHour || start.hour >= court.closingHour) {
      return const Err(OutsideOperatingHoursFailure());
    }

    // Reconfere contra a agenda: entre a tela carregar e o toque no botão,
    // outra pessoa pode ter reservado o mesmo horário.
    final existing = await _bookings.forCourtOn(courtId: court.id, day: start);
    if (existing case Err<List<Booking>> error) return error.cast();

    final taken = (existing as Ok<List<Booking>>).value;
    if (taken.any((booking) => booking.startsAt(start))) {
      return const Err(SlotUnavailableFailure());
    }

    // A checagem acima é para dar mensagem boa ao usuário. A garantia real
    // está no id: o repositório recusa gravar um horário já ocupado.
    return _bookings.create(
      Booking(
        id: Booking.slotId(courtId: court.id, start: start),
        courtId: court.id,
        userId: userId,
        start: start,
      ),
    );
  }
}
