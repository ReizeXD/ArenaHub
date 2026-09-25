import '../../../../core/failure.dart';
import '../../domain/entities/booking_with_court.dart';

/// Estados da tela de reservas do usuário.
sealed class MyBookingsState {
  const MyBookingsState();
}

final class MyBookingsLoading extends MyBookingsState {
  const MyBookingsLoading();
}

final class MyBookingsLoaded extends MyBookingsState {
  const MyBookingsLoaded(this.bookings);

  final List<BookingWithCourt> bookings;

  List<BookingWithCourt> get upcoming =>
      bookings.where((b) => !b.isPast).toList();

  List<BookingWithCourt> get past =>
      bookings.where((b) => b.isPast).toList().reversed.toList();

  bool get isEmpty => bookings.isEmpty;
}

final class MyBookingsFailed extends MyBookingsState {
  const MyBookingsFailed(this.failure);

  final Failure failure;
}
