import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/presentation/pages/login_page.dart';
import 'package:arenahub/features/auth/presentation/pages/sign_up_page.dart';
import 'package:arenahub/features/auth/presentation/widgets/social_auth_widgets.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/domain/repositories/booking_repository.dart';
import 'package:arenahub/features/courts/domain/repositories/court_repository.dart';
import 'package:arenahub/features/courts/domain/services/court_image_storage.dart';
import 'package:arenahub/features/courts/presentation/pages/courts_page.dart';
import 'package:arenahub/features/courts/presentation/pages/home_shell.dart';
import 'package:arenahub/features/profile/presentation/controllers/app_mode_controller.dart';
import 'package:arenahub/features/profile/presentation/pages/profile_page.dart';
import 'package:arenahub/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/court_fakes.dart';
import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final agora = DateTime(2026, 9, 28, 9, 30);

  const publicCourt = Court(
    id: 'court-central',
    ownerId: 'dono-arena',
    name: 'Arena Central de Tênis',
    sport: Sport.beachTennis,
    address: 'Av. Esportiva, 100 — Centro',
    pricePerHourInCents: 10000,
    openingHour: 7,
    closingHour: 23,
  );

  Future<void> tocarEm(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Widget createApp({
    required controller,
    CourtRepository? courtRepository,
    BookingRepository? bookingRepository,
    CourtImageStorage? imageStorage,
    AppModeController? appModeController,
  }) {
    final courtRepo = courtRepository ?? InMemoryCourtRepository([publicCourt]);
    final bookingRepo = bookingRepository ?? FakeBookingRepository();
    final storage = imageStorage ?? FakeCourtImageStorage();

    final courtsCtrl = courtsControllerWith(repository: courtRepo);
    final bookingCtrl = bookingControllerWith(
      bookings: bookingRepo,
      now: () => agora,
    );
    final myBookingsCtrl = myBookingsControllerWith(
      bookings: bookingRepo,
      courts: courtRepo,
      now: () => agora,
    );
    final myCourtsCtrl = myCourtsControllerWith(
      courts: courtRepo,
      storage: storage,
      onCourtMutated: () async => courtsCtrl.load(),
    );
    final ownerAgendaCtrl = ownerAgendaControllerWith(
      bookings: bookingRepo,
      now: () => agora,
    );
    final appModeCtrl = appModeController ?? AppModeController();

    return ArenaHubApp(
      authController: controller,
      courtsController: courtsCtrl,
      bookingController: bookingCtrl,
      myBookingsController: myBookingsCtrl,
      myCourtsController: myCourtsCtrl,
      ownerAgendaController: ownerAgendaCtrl,
      appModeController: appModeCtrl,
    );
  }

  group('Jornada de Autenticação Social — E2E', () {
    testWidgets(
        'Fluxo Google Sign-In: login com 1 toque, navegação para catálogo, validação de sessão e logout',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemorySessionStorage();
      final repository = FakeAuthRepository();
      final auth = controllerWith(repository: repository, storage: storage);
      await auth.restoreSession();

      await tester.pumpWidget(createApp(controller: auth));
      await tester.pumpAndSettle();

      // 1. Tela inicial de Login
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);

      // 2. Aciona login social com o Google
      await tocarEm(tester, find.byType(GoogleSignInButton));

      // 3. Verifica transição direta para HomeShell (catálogo de quadras)
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(CourtsPage), findsOneWidget);
      expect(find.text('Olá, Atleta'), findsOneWidget);
      expect(find.text('Arena Central de Tênis'), findsOneWidget);

      // 4. Valida persistência da sessão no storage
      final savedSession = await storage.read();
      expect(savedSession, isNotNull);
      expect(savedSession?.user.email, 'atleta.google@arenahub.com');
      expect(savedSession?.user.fullName, 'Atleta Google');

      // 5. Navega para a aba Perfil e valida dados do usuário
      await tocarEm(tester, find.text('Perfil'));
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Atleta Google'), findsOneWidget);
      expect(find.text('atleta.google@arenahub.com'), findsOneWidget);

      // 6. Efetua logout e valida retorno seguro à LoginPage
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile_logout_button')),
        200,
      );
      await tocarEm(tester, find.byKey(const Key('profile_logout_button')));
      expect(find.byType(LoginPage), findsOneWidget);
      expect(await storage.read(), isNull);
    });

    testWidgets(
        'Fluxo Apple Sign-In: cadastro rápido em 1 toque na SignUpPage e acesso ao HomeShell',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = InMemorySessionStorage();
      final repository = FakeAuthRepository();
      final auth = controllerWith(repository: repository, storage: storage);
      await auth.restoreSession();

      await tester.pumpWidget(createApp(controller: auth));
      await tester.pumpAndSettle();

      // 1. Inicia na LoginPage e navega até SignUpPage
      expect(find.byType(LoginPage), findsOneWidget);
      await tocarEm(tester, find.text('Cadastre-se'));

      // 2. Verifica a SignUpPage e o botão da Apple
      expect(find.byType(SignUpPage), findsOneWidget);
      expect(find.byType(AppleSignInButton), findsOneWidget);
      expect(find.text('Cadastre-se com a Apple'), findsOneWidget);

      // 3. Realiza o cadastro social em 1 toque com a Apple
      await tocarEm(tester, find.byType(AppleSignInButton));

      // 4. Valida redirecionamento automático para a área autenticada
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(CourtsPage), findsOneWidget);
      expect(find.text('Olá, Atleta'), findsOneWidget);

      // 5. Valida informações da sessão e perfil
      final currentSession = await storage.read();
      expect(currentSession?.user.email, 'atleta.apple@arenahub.com');
      expect(currentSession?.user.fullName, 'Atleta Apple');

      await tocarEm(tester, find.text('Perfil'));
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Atleta Apple'), findsOneWidget);
      expect(find.text('atleta.apple@arenahub.com'), findsOneWidget);
    });

    testWidgets(
        'Fluxo de Cancelamento: cancelamento do diálogo nativo mantém a tela sem disparar erro',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = FakeAuthRepository(
        failure: const OAuthCancelledFailure(),
      );
      final auth = controllerWith(repository: repository);
      await auth.restoreSession();

      await tester.pumpWidget(createApp(controller: auth));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      // Usuário abre o fluxo do Google e cancela a seleção de conta
      await tocarEm(tester, find.byType(GoogleSignInButton));

      // A interface permanece na LoginPage de maneira silenciosa e sem erro
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // O usuário ainda pode usar o formulário tradicional ou tentar novamente
      await tester.enterText(
        find.byType(TextFormField).first,
        'jogador@arenahub.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'arena2026',
      );
      expect(find.text('jogador@arenahub.com'), findsOneWidget);
    });
  });
}
