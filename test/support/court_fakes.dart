import 'dart:async';
import 'dart:typed_data';

import 'package:arenahub/core/failure.dart';
import 'package:arenahub/core/result.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/booking.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/repositories/booking_repository.dart';
import 'package:arenahub/features/courts/domain/repositories/court_repository.dart';
import 'package:arenahub/features/courts/domain/services/court_image_storage.dart';
import 'package:arenahub/features/courts/domain/usecases/book_court.dart';
import 'package:arenahub/features/courts/domain/usecases/create_court.dart';
import 'package:arenahub/features/courts/domain/usecases/delete_court.dart';
import 'package:arenahub/features/courts/domain/usecases/get_court_availability.dart';
import 'package:arenahub/features/courts/domain/usecases/get_owner_court_agenda.dart';
import 'package:arenahub/features/courts/domain/usecases/list_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_bookings.dart';
import 'package:arenahub/features/courts/domain/usecases/list_my_courts.dart';
import 'package:arenahub/features/courts/domain/usecases/update_court.dart';
import 'package:arenahub/features/courts/presentation/controllers/booking_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_bookings_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/owner_agenda_controller.dart';

/// Quadra de teste: abre 8h, fecha 12h — quatro horários, fácil de conferir.
const Court testCourt = Court(
  id: 'quadra-1',
  ownerId: 'owner-1',
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
  String nextIdentity() => 'failing_court_id';

  @override
  Future<Result<List<Court>>> listAll() async => Err(failure);

  @override
  Future<Result<List<Court>>> listByOwner(String ownerId) async => Err(failure);

  @override
  Future<Result<Court>> findById(String id) async => Err(failure);

  @override
  Future<Result<Court>> create(Court court) async => Err(failure);

  @override
  Future<Result<Court>> update(Court court) async => Err(failure);

  @override
  Future<Result<void>> delete(String id) async => Err(failure);
}

/// Dublê de `CourtImageStorage` para testes de criação e atualização.
class FakeCourtImageStorage implements CourtImageStorage {
  FakeCourtImageStorage({this.urlToReturn = 'https://fake.url/image.jpg'});

  final String urlToReturn;
  Failure? failure;
  int uploadCalls = 0;

  @override
  Future<Result<String>> upload({
    required String ownerId,
    required String courtId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    uploadCalls++;
    if (failure != null) return Err(failure!);
    return Ok(urlToReturn);
  }
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
    CourtsController(ListCourts(repository ?? InMemoryCourtRepository()));

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
        courts ?? InMemoryCourtRepository(),
        now: now,
      ),
    );

/// Monta um `MyCourtsController` sobre dublês.
MyCourtsController myCourtsControllerWith({
  CourtRepository? courts,
  CourtImageStorage? storage,
  FutureOr<void> Function()? onCourtMutated,
}) {
  final repository = courts ?? InMemoryCourtRepository();
  final imgStorage = storage ?? FakeCourtImageStorage();
  return MyCourtsController(
    listMyCourts: ListMyCourts(repository),
    createCourt: CreateCourt(repository, imgStorage),
    updateCourt: UpdateCourt(repository, imgStorage),
    deleteCourt: DeleteCourt(repository),
    onCourtMutated: onCourtMutated,
  );
}

/// Monta um `OwnerAgendaController` sobre dublês.
OwnerAgendaController ownerAgendaControllerWith({
  BookingRepository? bookings,
  DateTime Function()? now,
  int daysAhead = OwnerAgendaController.defaultDaysAhead,
}) {
  final repository = bookings ?? FakeBookingRepository();
  return OwnerAgendaController(
    GetOwnerCourtAgenda(repository, now: now),
    now: now,
    daysAhead: daysAhead,
  );
}
