import 'package:flutter/foundation.dart';

import '../../domain/entities/booking_with_court.dart';
import '../../domain/usecases/list_my_bookings.dart';
import '../states/my_bookings_state.dart';

/// Liga a tela de reservas ao caso de uso.
class MyBookingsController extends ChangeNotifier {
  MyBookingsController(this._listMyBookings);

  final ListMyBookings _listMyBookings;

  MyBookingsState _state = const MyBookingsLoading();
  MyBookingsState get state => _state;

  Future<void> load(String userId) async {
    _emit(const MyBookingsLoading());
    _emit(
      (await _listMyBookings(userId)).fold(
        onSuccess: (List<BookingWithCourt> bookings) =>
            MyBookingsLoaded(bookings),
        onFailure: MyBookingsFailed.new,
      ),
    );
  }

  void _emit(MyBookingsState next) {
    _state = next;
    notifyListeners();
  }
}
