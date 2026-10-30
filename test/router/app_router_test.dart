import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/entities/user.dart';
import 'package:arenahub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:arenahub/features/auth/presentation/pages/login_page.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/controllers/courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'package:arenahub/features/courts/presentation/pages/court_form_page.dart';
import 'package:arenahub/features/courts/presentation/pages/my_courts_page.dart';
import 'package:arenahub/features/courts/presentation/pages/owner_court_agenda_page.dart';
import 'package:arenahub/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/court_fakes.dart';
import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testOwner = User(
    id: 'owner-1',
    fullName: 'Carlos Alberto',
    email: 'carlos@arenahub.com',
    role: Role.owner,
  );

  final activeSession = AuthSession(
    token: 'test-token',
    user: testOwner,
    issuedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  const sampleCourt = Court(
    id: 'court-10',
    ownerId: 'owner-1',
    name: 'Quadra de Beach Tennis Central',
    sport: Sport.beachTennis,
    address: 'Av. Litorânea, 100',
    pricePerHourInCents: 12000,
    openingHour: 7,
    closingHour: 22,
  );

  late InMemoryCourtRepository courtRepo;
  late FakeBookingRepository bookingRepo;
  late CourtsController courtsController;
  late MyCourtsController myCourtsController;
  late OwnerAgendaController ownerAgendaController;

  setUp(() {
    courtRepo = InMemoryCourtRepository([sampleCourt]);
    bookingRepo = FakeBookingRepository();
    courtsController = courtsControllerWith(repository: courtRepo);
    myCourtsController = myCourtsControllerWith(courts: courtRepo);
    ownerAgendaController = ownerAgendaControllerWith(bookings: bookingRepo);
  });

  Future<AuthController> createAuthenticatedController() async {
    final storage = InMemorySessionStorage();
    await storage.save(activeSession);
    final auth = controllerWith(storage: storage);
    await auth.restoreSession();
    return auth;
  }

  Widget buildSubject({
    required AuthController authController,
    String? initialLocation,
  }) {
    final router = buildAppRouter(
      auth: authController,
      courts: courtsController,
      myCourts: myCourtsController,
    );

    if (initialLocation != null) {
      router.go(initialLocation);
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<CourtsController>.value(value: courtsController),
        ChangeNotifierProvider<MyCourtsController>.value(
          value: myCourtsController,
        ),
        ChangeNotifierProvider<OwnerAgendaController>.value(
          value: ownerAgendaController,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('AppRouter — Rotas do Proprietário', () {
    testWidgets('rota /my-courts carrega a página MyCourtsPage',
        (tester) async {
      final auth = await createAuthenticatedController();

      await tester.pumpWidget(
        buildSubject(
          authController: auth,
          initialLocation: AppRoutes.myCourts,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MyCourtsPage), findsOneWidget);
      expect(find.text('Minhas Quadras'), findsOneWidget);
      expect(find.text('Quadra de Beach Tennis Central'), findsOneWidget);
    });

    testWidgets('rota /my-courts/new carrega CourtFormPage em modo de criação',
        (tester) async {
      final auth = await createAuthenticatedController();

      await tester.pumpWidget(
        buildSubject(
          authController: auth,
          initialLocation: AppRoutes.myCourtsNew,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CourtFormPage), findsOneWidget);
      expect(find.text('Nova Quadra'), findsOneWidget);
      expect(find.text('Cadastrar Quadra'), findsOneWidget);
    });

    testWidgets('rota /my-courts/:id/edit carrega CourtFormPage com os dados da quadra',
        (tester) async {
      final auth = await createAuthenticatedController();
      await myCourtsController.load(testOwner.id);

      await tester.pumpWidget(
        buildSubject(
          authController: auth,
          initialLocation: AppRoutes.myCourtEdit(sampleCourt.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CourtFormPage), findsOneWidget);
      expect(find.text('Editar Quadra'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
      expect(find.text('Quadra de Beach Tennis Central'), findsOneWidget);
    });

    testWidgets('rota /my-courts/:id/agenda carrega OwnerCourtAgendaPage',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = await createAuthenticatedController();
      await myCourtsController.load(testOwner.id);

      await tester.pumpWidget(
        buildSubject(
          authController: auth,
          initialLocation: AppRoutes.myCourtAgenda(sampleCourt.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OwnerCourtAgendaPage), findsOneWidget);
      expect(find.text('Agenda da Quadra'), findsOneWidget);
      expect(find.text('Quadra de Beach Tennis Central'), findsOneWidget);
    });

    testWidgets('rota /my-courts/:id/agenda com quadra inexistente redireciona para /my-courts',
        (tester) async {
      final auth = await createAuthenticatedController();

      await tester.pumpWidget(
        buildSubject(
          authController: auth,
          initialLocation: AppRoutes.myCourtAgenda('quadra-inexistente'),
        ),
      );
      await tester.pumpAndSettle();

      // Redireciona para /my-courts
      expect(find.byType(MyCourtsPage), findsOneWidget);
      expect(find.byType(OwnerCourtAgendaPage), findsNothing);
    });

    testWidgets('usuário não autenticado tentando acessar /my-courts é redirecionado para /login',
        (tester) async {
      final unauth = controllerWith(); // Sem sessão salva
      await unauth.restoreSession();

      await tester.pumpWidget(
        buildSubject(
          authController: unauth,
          initialLocation: AppRoutes.myCourts,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(MyCourtsPage), findsNothing);
    });
  });
}
