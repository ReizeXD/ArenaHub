import 'package:arenahub/di/auth_mode.dart';
import 'package:arenahub/di/injector.dart';
import 'package:arenahub/features/auth/data/datasources/in_memory_user_data_source.dart';
import 'package:arenahub/features/courts/data/services/firebase_court_image_storage.dart';
import 'package:arenahub/features/courts/data/services/memory_court_image_storage.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Injector', () {
    test('bootstrap no modo local instancia todos os controladores e serviços em memória',
        () async {
      final userDataSource = InMemoryUserDataSource();
      final imageStorage = MemoryCourtImageStorage();

      final injector = await Injector.bootstrap(
        mode: AuthMode.local,
        userDataSource: userDataSource,
        imageStorage: imageStorage,
      );

      // Controladores principais do atleta
      expect(injector.authController, isNotNull);
      expect(injector.courtsController, isNotNull);
      expect(injector.bookingController, isNotNull);
      expect(injector.myBookingsController, isNotNull);

      // Novos controladores do proprietário
      expect(injector.myCourtsController, isA<MyCourtsController>());
      expect(injector.ownerAgendaController, isA<OwnerAgendaController>());

      // Serviço de armazenamento de imagens
      expect(injector.courtImageStorage, isA<MemoryCourtImageStorage>());
      expect(identical(injector.courtImageStorage, imageStorage), isTrue);
    });

    test('quando imageStorage não é fornecido no modo local, usa MemoryCourtImageStorage',
        () async {
      final userDataSource = InMemoryUserDataSource();

      final injector = await Injector.bootstrap(
        mode: AuthMode.local,
        userDataSource: userDataSource,
      );

      expect(injector.courtImageStorage, isA<MemoryCourtImageStorage>());
      expect(injector.myCourtsController, isA<MyCourtsController>());
      expect(injector.ownerAgendaController, isA<OwnerAgendaController>());
    });

    test('seleção do tipo de armazenamento de imagem conforme o AuthMode', () {
      // Modo local usa armazenamento em memória
      final localStorage = MemoryCourtImageStorage();
      expect(localStorage, isA<MemoryCourtImageStorage>());

      // Modo Firebase usa o serviço do Firebase Storage
      final firebaseStorage = FirebaseCourtImageStorage();
      expect(firebaseStorage, isA<FirebaseCourtImageStorage>());
    });
  });
}
