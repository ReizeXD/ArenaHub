import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/repositories/booking_repository.dart';
import 'package:arenahub/features/courts/domain/repositories/court_repository.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/usecases/book_court.dart';
import 'package:arenahub/features/courts/domain/usecases/get_court_availability.dart';
import 'package:arenahub/features/courts/domain/usecases/list_courts.dart';
import 'package:arenahub/features/courts/presentation/controllers/booking_controller.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_bookings.dart';
import 'package:arenahub/features/courts/presentation/controllers/courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_bookings_controller.dart';

/// Quadra de teste: abre 8h, fecha 12h — quatro horários, fácil de conferir.
const Court testCourt = Court(
  id: 'quadra-1',
  name: 'Arena de Teste',
  sport: Sport.futsal,
  address: 'Rua de Teste, 100',
  pricePerHourInCents: 9000,
  openingHour: 8,
  closingHour: 12,
);

/// `CourtRepository` que sempre falha — para exercitar o caminho de erro.
class FailingCourtRepository implements CourtRepository {
  const FailingCourtRepository([this.failure = const StorageFailure()]);

  final Failure failure;

  @override
  Future<Result<List<Court>>> listAll() async => Err(failure);

  @override
  Future<Result<Court>> findById(String id) async => Err(failure);
}

/// `BookingRepository` em memória, com contadores para os testes.
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository([List<Booking>? initial])
      : _bookings = [...?initial];

  final List<Booking> _bookings;

  int createCalls = 0;

  List<Booking> get all => List.unmodifiable(_bookings);

  @override
  Future<Result<List<Booking>>> forCourtOn({
    required String courtId,
    required DateTime day,
  }) async =>
      Ok(
        _bookings
            .where(
              (b) =>
                  b.courtId == courtId &&
                  b.start.year == day.year &&
                  b.start.month == day.month &&
                  b.start.day == day.day,
            )
            .toList(),
      );

  @override
  Future<Result<List<Booking>>> ofUser(String userId) async =>
      Ok(_bookings.where((b) => b.userId == userId).toList());

  @override
  Future<Result<Booking>> create(Booking booking) async {
    createCalls++;
    _bookings.add(booking);
    return Ok(booking);
  }
}

/// Monta um `CourtsController` sobre o catálogo em memória (ou um dublê).
CourtsController courtsControllerWith({CourtRepository? repository}) =>
    CourtsController(ListCourts(repository ?? const InMemoryCourtRepository()));

/// Monta um `BookingController` com relógio fixo, como o composition root faz
/// com as implementações reais.
BookingController bookingControllerWith({
  BookingRepository? bookings,
  DateTime Function()? now,
}) {
  final repository = bookings ?? FakeBookingRepository();
  return BookingController(
    GetCourtAvailability(repository, now: now),
    BookCourt(repository, now: now),
    now: now,
  );
}

/// Monta um `MyBookingsController` sobre dublês.
MyBookingsController myBookingsControllerWith({
  BookingRepository? bookings,
  CourtRepository? courts,
  DateTime Function()? now,
}) =>
    MyBookingsController(
      ListMyBookings(
        bookings ?? FakeBookingRepository(),
        courts ?? const InMemoryCourtRepository(),
        now: now,
      ),
    );
