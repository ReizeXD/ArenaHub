import '../../../../core/result.dart';
import '../entities/booking.dart';
import '../entities/court.dart';
import '../entities/time_slot.dart';
import '../repositories/booking_repository.dart';

/// Caso de uso: montar a agenda de um dia para uma quadra.
///
/// A regra de "qual horário aparece livre" vive aqui, e não na tela: um
/// horário está disponível quando está dentro do funcionamento da quadra,
/// ainda não passou e ninguém reservou.
class GetCourtAvailability {
  const GetCourtAvailability(this._bookings, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final BookingRepository _bookings;

  /// Injetável para o teste poder fixar "agora" e não depender do relógio.
  final DateTime Function() _now;

  Future<Result<List<TimeSlot>>> call({
    required Court court,
    required DateTime day,
  }) async {
    final result = await _bookings.forCourtOn(courtId: court.id, day: day);
    if (result case Err<List<Booking>> error) return error.cast();

    final taken = (result as Ok<List<Booking>>).value;
    final now = _now();

    final slots = <TimeSlot>[];
    for (var hour = court.openingHour; hour < court.closingHour; hour++) {
      final start = DateTime(day.year, day.month, day.day, hour);

      final isPast = start.isBefore(now);
      final isTaken = taken.any((booking) => booking.startsAt(start));

      slots.add(TimeSlot(start: start, isAvailable: !isPast && !isTaken));
    }
    return Ok(slots);
  }
}
