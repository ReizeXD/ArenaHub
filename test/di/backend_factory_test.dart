import 'package:arenahub/di/factories/backend_factory.dart';
import 'package:arenahub/di/factories/local_backend_factory.dart';
import 'package:arenahub/di/injector.dart';
import 'package:arenahub/features/auth/data/datasources/in_memory_user_data_source.dart';
import 'package:arenahub/features/auth/data/repositories/local_auth_repository.dart';
import 'package:arenahub/features/auth/domain/repositories/auth_repository.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_booking_repository.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/data/services/memory_court_image_storage.dart';
import 'package:arenahub/features/courts/domain/repositories/booking_repository.dart';
import 'package:arenahub/features/courts/domain/repositories/court_repository.dart';
import 'package:arenahub/features/courts/domain/services/court_image_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalBackendFactory (Abstract Factory)', () {
    test('cria toda a família de infraestrutura compatível para modo local',
        () async {
      final userDataSource = InMemoryUserDataSource();
      final BackendFactory factory = LocalBackendFactory(
        userDataSource: userDataSource,
      );

      await factory.initialize();
      final authRepo = await factory.createAuthRepository();
      final courtRepo = factory.createCourtRepository();
      final bookingRepo = factory.createBookingRepository();
      final imageStorage = factory.createCourtImageStorage();

      expect(authRepo, isA<LocalAuthRepository>());
      expect(courtRepo, isA<InMemoryCourtRepository>());
      expect(bookingRepo, isA<InMemoryBookingRepository>());
      expect(imageStorage, isA<MemoryCourtImageStorage>());

      // Verifica se os usuários de demonstração foram semeados na fonte local.
      final demoUser = await userDataSource.findByEmail('jogador@arenahub.com');
      expect(demoUser, isNotNull);
    });
  });

  group('Injector como cliente do BackendFactory', () {
    test('delega a criação de toda a família para a BackendFactory injetada',
        () async {
      final spyFactory = _SpyBackendFactory(
        LocalBackendFactory(userDataSource: InMemoryUserDataSource()),
      );

      final injector = await Injector.bootstrap(factory: spyFactory);

      expect(spyFactory.initializeCalls, 1);
      expect(spyFactory.authCalls, 1);
      expect(spyFactory.courtCalls, 1);
      expect(spyFactory.bookingCalls, 1);
      expect(spyFactory.imageStorageCalls, 1);
      expect(injector.courtImageStorage, isA<MemoryCourtImageStorage>());
    });
  });
}

class _SpyBackendFactory implements BackendFactory {
  _SpyBackendFactory(this._inner);

  final BackendFactory _inner;
  int initializeCalls = 0;
  int authCalls = 0;
  int courtCalls = 0;
  int bookingCalls = 0;
  int imageStorageCalls = 0;

  @override
  Future<void> initialize() {
    initializeCalls++;
    return _inner.initialize();
  }

  @override
  Future<AuthRepository> createAuthRepository() {
    authCalls++;
    return _inner.createAuthRepository();
  }

  @override
  CourtRepository createCourtRepository() {
    courtCalls++;
    return _inner.createCourtRepository();
  }

  @override
  BookingRepository createBookingRepository() {
    bookingCalls++;
    return _inner.createBookingRepository();
  }

  @override
  CourtImageStorage createCourtImageStorage() {
    imageStorageCalls++;
    return _inner.createCourtImageStorage();
  }
}
