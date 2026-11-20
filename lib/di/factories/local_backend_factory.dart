import 'package:flutter/foundation.dart' show kIsWeb;

import '../../features/auth/data/datasources/in_memory_user_data_source.dart';
import '../../features/auth/data/datasources/sqflite_user_data_source.dart';
import '../../features/auth/data/datasources/user_data_source.dart';
import '../../features/auth/data/repositories/local_auth_repository.dart';
import '../../features/auth/data/seed/demo_user_seeder.dart';
import '../../features/auth/data/services/pbkdf2_password_hasher.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/courts/data/repositories/in_memory_booking_repository.dart';
import '../../features/courts/data/repositories/in_memory_court_repository.dart';
import '../../features/courts/data/services/memory_court_image_storage.dart';
import '../../features/courts/domain/repositories/booking_repository.dart';
import '../../features/courts/domain/repositories/court_repository.dart';
import '../../features/courts/domain/services/court_image_storage.dart';
import 'backend_factory.dart';

/// Fábrica Concreta 1: cria a família de objetos para o modo Local (Offline).
/// Usa SQLite/Memória e não precisa de internet nem de Firebase configurado.
class LocalBackendFactory implements BackendFactory {
  LocalBackendFactory({this.userDataSource});

  final UserDataSource? userDataSource;

  @override
  Future<void> initialize() async {
    // Modo local não precisa inicializar serviços na nuvem.
  }

  @override
  Future<AuthRepository> createAuthRepository() async {
    final passwordHasher = Pbkdf2PasswordHasher();
    final UserDataSource source =
        userDataSource ?? await _openUserDataSource();

    // Cria as contas de demonstração no banco local.
    await DemoUserSeeder(source, passwordHasher).seed();

    return LocalAuthRepository(source, passwordHasher);
  }

  Future<UserDataSource> _openUserDataSource() async {
    if (kIsWeb) {
      return InMemoryUserDataSource();
    }
    return SqfliteUserDataSource.open();
  }

  @override
  CourtRepository createCourtRepository() {
    return InMemoryCourtRepository();
  }

  @override
  BookingRepository createBookingRepository() {
    return InMemoryBookingRepository();
  }

  @override
  CourtImageStorage createCourtImageStorage() {
    return MemoryCourtImageStorage();
  }
}
