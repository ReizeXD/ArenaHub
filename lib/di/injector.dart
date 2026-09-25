import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/datasources/firestore_user_profile_data_source.dart';
import '../features/auth/data/datasources/in_memory_user_data_source.dart';
import '../features/auth/data/datasources/sqflite_user_data_source.dart';
import '../features/auth/data/datasources/user_data_source.dart';
import '../features/auth/data/repositories/firebase_auth_repository.dart';
import '../features/auth/data/repositories/local_auth_repository.dart';
import '../features/auth/data/seed/demo_user_seeder.dart';
import '../features/auth/data/services/pbkdf2_password_hasher.dart';
import '../features/auth/data/services/prefs_session_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/services/session_storage.dart';
import '../features/auth/domain/usecases/get_current_session.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/courts/data/repositories/firestore_booking_repository.dart';
import '../features/courts/data/repositories/firestore_court_repository.dart';
import '../features/courts/data/repositories/in_memory_booking_repository.dart';
import '../features/courts/data/repositories/in_memory_court_repository.dart';
import '../features/courts/data/repositories/seeding_court_repository.dart';
import '../features/courts/data/seed/firestore_court_seeder.dart';
import '../features/courts/domain/repositories/booking_repository.dart';
import '../features/courts/domain/repositories/court_repository.dart';
import '../features/courts/domain/usecases/book_court.dart';
import '../features/courts/domain/usecases/get_court_availability.dart';
import '../features/courts/domain/usecases/list_courts.dart';
import '../features/courts/domain/usecases/list_my_bookings.dart';
import '../features/courts/presentation/controllers/booking_controller.dart';
import '../features/courts/presentation/controllers/courts_controller.dart';
import '../features/courts/presentation/controllers/my_bookings_controller.dart';
import '../firebase_options.dart';
import 'auth_mode.dart';

/// Composition root: o **único** ponto do app que menciona classes concretas.
///
/// Os dois `switch` abaixo são o projeto inteiro trocando de infraestrutura.
/// Nenhuma entidade, caso de uso, controller ou tela sabe que essa escolha
/// existe — todos conhecem apenas as interfaces.
class Injector {
  const Injector._(
    this.authController,
    this.courtsController,
    this.bookingController,
    this.myBookingsController,
  );

  final AuthController authController;
  final CourtsController courtsController;
  final BookingController bookingController;
  final MyBookingsController myBookingsController;

  static Future<Injector> bootstrap({AuthMode mode = AuthMode.local}) async {
    if (mode == AuthMode.firebase) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final SessionStorage sessionStorage = PrefsSessionStorage(preferences);

    final AuthRepository authRepository = await _buildAuthRepository(mode);

    final controller = AuthController(
      SignIn(authRepository, sessionStorage),
      SignUp(authRepository, sessionStorage),
      SignOut(sessionStorage),
      GetCurrentSession(sessionStorage),
    );
    await controller.restoreSession();

    final (CourtRepository courts, BookingRepository bookings) =
        _buildCourtRepositories(mode);

    return Injector._(
      controller,
      CourtsController(ListCourts(courts)),
      BookingController(
        GetCourtAvailability(bookings),
        BookCourt(bookings),
      ),
      MyBookingsController(ListMyBookings(bookings, courts)),
    );
  }

  // --- autenticação ---------------------------------------------------

  static Future<AuthRepository> _buildAuthRepository(AuthMode mode) async =>
      switch (mode) {
        AuthMode.local => _buildLocalAuthRepository(),
        AuthMode.firebase => FirebaseAuthRepository(
            fb.FirebaseAuth.instance,
            FirestoreUserProfileDataSource(FirebaseFirestore.instance),
          ),
      };

  static Future<AuthRepository> _buildLocalAuthRepository() async {
    final passwordHasher = Pbkdf2PasswordHasher();
    final UserDataSource userDataSource = await _openUserDataSource();

    // Contas de demonstração só fazem sentido no modo local; no Firebase os
    // usuários são criados pelo cadastro ou pelo console.
    await DemoUserSeeder(userDataSource, passwordHasher).seed();

    return LocalAuthRepository(userDataSource, passwordHasher);
  }

  /// SQLite no aparelho; em memória na web, onde o plugin nativo não existe.
  static Future<UserDataSource> _openUserDataSource() async =>
      kIsWeb ? InMemoryUserDataSource() : await SqfliteUserDataSource.open();

  // --- quadras e reservas ---------------------------------------------

  static (CourtRepository, BookingRepository) _buildCourtRepositories(
    AuthMode mode,
  ) =>
      switch (mode) {
        AuthMode.local => (
            const InMemoryCourtRepository(),
            InMemoryBookingRepository(),
          ),
        AuthMode.firebase => _firestoreCourtRepositories(),
      };

  static (CourtRepository, BookingRepository) _firestoreCourtRepositories() {
    final firestore = FirebaseFirestore.instance;

    return (
      // O decorador semeia o catálogo na primeira leitura, enquanto não
      // existe cadastro de quadras pelo dono da arena.
      SeedingCourtRepository(
        FirestoreCourtRepository(firestore),
        FirestoreCourtSeeder(firestore).seed,
      ),
      FirestoreBookingRepository(firestore),
    );
  }
}
