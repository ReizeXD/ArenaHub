import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/datasources/user_data_source.dart';
import '../features/auth/data/services/prefs_session_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/services/session_storage.dart';
import '../features/auth/domain/usecases/get_current_session.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_in_with_apple.dart';
import '../features/auth/domain/usecases/sign_in_with_google.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';
import '../features/auth/presentation/auth_strategy_factory.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/courts/domain/repositories/booking_repository.dart';
import '../features/courts/domain/repositories/court_repository.dart';
import '../features/courts/domain/services/court_image_storage.dart';
import '../features/courts/domain/usecases/book_court.dart';
import '../features/courts/domain/usecases/create_court.dart';
import '../features/courts/domain/usecases/delete_court.dart';
import '../features/courts/domain/usecases/get_court_availability.dart';
import '../features/courts/domain/usecases/get_owner_court_agenda.dart';
import '../features/courts/domain/usecases/list_courts.dart';
import '../features/courts/domain/usecases/list_my_bookings.dart';
import '../features/courts/domain/usecases/list_my_courts.dart';
import '../features/courts/domain/usecases/update_court.dart';
import '../features/courts/presentation/controllers/booking_controller.dart';
import '../features/courts/presentation/controllers/courts_controller.dart';
import '../features/courts/presentation/controllers/my_bookings_controller.dart';
import '../features/courts/presentation/controllers/my_courts_controller.dart';
import '../features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'auth_mode.dart';
import 'factories/backend_factory.dart';
import 'factories/firebase_backend_factory.dart';
import 'factories/local_backend_factory.dart';

/// Composition root: cliente do Abstract Factory ([BackendFactory]).
/// Monta toda a árvore de dependências do app escolhendo a fábrica certa.
class Injector {
  const Injector._(
    this.authController,
    this.authStrategies,
    this.courtsController,
    this.bookingController,
    this.myBookingsController,
    this.myCourtsController,
    this.ownerAgendaController,
    this.courtImageStorage,
  );

  final AuthController authController;
  final AuthStrategyFactory authStrategies;
  final CourtsController courtsController;
  final BookingController bookingController;
  final MyBookingsController myBookingsController;
  final MyCourtsController myCourtsController;
  final OwnerAgendaController ownerAgendaController;
  final CourtImageStorage courtImageStorage;

  static Future<Injector> bootstrap({
    AuthMode mode = AuthMode.local,
    UserDataSource? userDataSource,
    CourtImageStorage? imageStorage,
    BackendFactory? factory,
  }) async {
    // Escolhe a fábrica abstrata conforme o modo (Local ou Firebase).
    final BackendFactory backendFactory =
        factory ?? _selectFactory(mode, userDataSource: userDataSource);

    await backendFactory.initialize();

    final preferences = await SharedPreferences.getInstance();
    final SessionStorage sessionStorage = PrefsSessionStorage(preferences);

    // Pede à fábrica os produtos da mesma família compatível.
    final AuthRepository authRepository =
        await backendFactory.createAuthRepository();
    final CourtRepository courts = backendFactory.createCourtRepository();
    final BookingRepository bookings = backendFactory.createBookingRepository();
    final CourtImageStorage storage =
        imageStorage ?? backendFactory.createCourtImageStorage();

    final controller = AuthController(
      SignUp(authRepository, sessionStorage),
      SignOut(sessionStorage),
      GetCurrentSession(sessionStorage),
    );
    final authStrategies = AuthStrategyFactory(
      signIn: SignIn(authRepository, sessionStorage),
      signInWithGoogle: SignInWithGoogle(authRepository, sessionStorage),
      signInWithApple: SignInWithApple(authRepository, sessionStorage),
    );
    await controller.restoreSession();

    final courtsController = CourtsController(ListCourts(courts));

    final myCourtsController = MyCourtsController(
      listMyCourts: ListMyCourts(courts),
      createCourt: CreateCourt(courts, storage),
      updateCourt: UpdateCourt(courts, storage),
      deleteCourt: DeleteCourt(courts),
      onCourtMutated: () async => courtsController.load(),
    );

    final ownerAgendaController = OwnerAgendaController(
      GetOwnerCourtAgenda(bookings),
    );

    return Injector._(
      controller,
      authStrategies,
      courtsController,
      BookingController(
        GetCourtAvailability(bookings),
        BookCourt(bookings),
      ),
      MyBookingsController(ListMyBookings(bookings, courts)),
      myCourtsController,
      ownerAgendaController,
      storage,
    );
  }

  static BackendFactory _selectFactory(
    AuthMode mode, {
    UserDataSource? userDataSource,
  }) {
    if (mode == AuthMode.firebase) {
      return FirebaseBackendFactory();
    }
    return LocalBackendFactory(userDataSource: userDataSource);
  }
}
