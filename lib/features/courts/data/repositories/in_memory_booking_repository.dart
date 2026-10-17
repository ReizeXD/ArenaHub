import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

/// [BookingRepository] guardando as reservas em memória.
class InMemoryBookingRepository implements BookingRepository {
  final List<Booking> _bookings = <Booking>[];

  @override
  Future<Result<List<Booking>>> forCourtOn({
    required String courtId,
    required DateTime day,
  }) async =>
      Ok(
        _bookings
            .where(
              (booking) =>
                  booking.courtId == courtId &&
                  booking.start.year == day.year &&
                  booking.start.month == day.month &&
                  booking.start.day == day.day,
            )
            .toList(),
      );

  @override
  Future<Result<List<Booking>>> ofUser(String userId) async {
    final mine = _bookings.where((booking) => booking.userId == userId).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return Ok(mine);
  }

  @override
  Future<Result<Booking>> create(Booking booking) async {
    // Mesma garantia que o adaptador do Firestore dá pelo id do documento:
    // dois pedidos para o mesmo horário, só o primeiro entra. Os dois se
    // comportam igual, e é isso que sustenta a substituição de Liskov.
    if (_bookings.any((existing) => existing.id == booking.id)) {
      return const Err(SlotUnavailableFailure());
    }
    _bookings.add(booking);
    return Ok(booking);
  }
}
