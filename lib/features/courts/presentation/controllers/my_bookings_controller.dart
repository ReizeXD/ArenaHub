import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
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
    final result = await _listMyBookings(userId);
    if (result is Ok<List<BookingWithCourt>>) {
      _emit(MyBookingsLoaded(result.value));
    } else if (result is Err<List<BookingWithCourt>>) {
      _emit(MyBookingsFailed(result.failure));
    }
  }

  void _emit(MyBookingsState next) {
    _state = next;
    notifyListeners();
  }
}
