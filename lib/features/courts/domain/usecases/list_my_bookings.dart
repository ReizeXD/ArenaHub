import '../../../../core/result.dart';
import '../entities/booking.dart';
import '../entities/booking_with_court.dart';
import '../entities/court.dart';
import '../repositories/booking_repository.dart';
import '../repositories/court_repository.dart';

/// Caso de uso: as reservas do usuário, com a quadra de cada uma.
class ListMyBookings {
  const ListMyBookings(
    this._bookings,
    this._courts, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BookingRepository _bookings;
  final CourtRepository _courts;
  final DateTime Function() _now;

  Future<Result<List<BookingWithCourt>>> call(String userId) async {
    final bookingsResult = await _bookings.ofUser(userId);
    if (bookingsResult case Err<List<Booking>> error) return error.cast();

    final courtsResult = await _courts.listAll();
    if (courtsResult case Err<List<Court>> error) return error.cast();

    final courtsById = <String, Court>{
      for (final court in (courtsResult as Ok<List<Court>>).value)
        court.id: court,
    };

    final now = _now();
    final joined = <BookingWithCourt>[];

    for (final booking in (bookingsResult as Ok<List<Booking>>).value) {
      final court = courtsById[booking.courtId];
      if (court == null) continue;

      joined.add(
        BookingWithCourt(
          booking: booking,
          court: court,
          isPast: booking.end.isBefore(now),
        ),
      );
    }

    joined.sort((a, b) => a.booking.start.compareTo(b.booking.start));
    return Ok(joined);
  }
}
