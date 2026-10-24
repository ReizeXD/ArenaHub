import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../entities/booking.dart';
import '../entities/court.dart';
import '../entities/owner_slot_info.dart';
import '../repositories/booking_repository.dart';

/// Caso de uso: montar a agenda detalhada de um dia na visão do dono da quadra.
class GetOwnerCourtAgenda {
  const GetOwnerCourtAgenda(this._bookings, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final BookingRepository _bookings;
  final DateTime Function() _now;

  Future<Result<List<OwnerSlotInfo>>> call({
    required Court court,
    required DateTime day,
    String? userId,
  }) async {
    if (userId != null && !court.isOwnedBy(userId)) {
      return const Err(UnauthorizedCourtActionFailure());
    }

    final result = await _bookings.forCourtOn(courtId: court.id, day: day);
    if (result case Err<List<Booking>> error) return error.cast();

    final taken = (result as Ok<List<Booking>>).value;
    final now = _now();

    final slots = <OwnerSlotInfo>[];
    for (var hour = court.openingHour; hour < court.closingHour; hour++) {
      final start = DateTime(day.year, day.month, day.day, hour);
      final booking = taken.where((b) => b.startsAt(start)).firstOrNull;

      slots.add(
        OwnerSlotInfo(
          start: start,
          isPast: start.isBefore(now),
          booking: booking,
        ),
      );
    }
    return Ok(slots);
  }
}
