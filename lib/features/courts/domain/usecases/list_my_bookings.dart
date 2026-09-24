import '../../../../core/result.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

/// Caso de uso: as reservas do usuário logado.
class ListMyBookings {
  const ListMyBookings(this._bookings);

  final BookingRepository _bookings;

  Future<Result<List<Booking>>> call(String userId) =>
      _bookings.ofUser(userId);
}
