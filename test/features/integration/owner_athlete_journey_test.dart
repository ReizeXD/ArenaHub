import 'package:arenahub/features/auth/presentation/pages/login_page.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/courts/presentation/pages/court_detail_page.dart';
import 'package:arenahub/features/courts/presentation/pages/court_form_page.dart';
import 'package:arenahub/features/courts/presentation/pages/courts_page.dart';
import 'package:arenahub/features/courts/presentation/pages/home_shell.dart';
import 'package:arenahub/features/courts/presentation/pages/my_bookings_page.dart';
import 'package:arenahub/features/courts/presentation/pages/my_courts_page.dart';
import 'package:arenahub/features/courts/presentation/pages/owner_court_agenda_page.dart';
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

  Future<void> tocarEm(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  const publicCourt = Court(
    id: 'court-paju',
    ownerId: 'outro-dono',
    name: 'Quadra Pajuçara',
    sport: Sport.beachTennis,
    address: 'R. Jangadeiros Alagoanos, 820 — Pajuçara',
    pricePerHourInCents: 12000,
    openingHour: 8,
    closingHour: 22,
  );

  group('Jornada Completa do Usuário — Atleta & Proprietário (Modo Airbnb)', () {
    testWidgets('percorre todo o ciclo de vida: autenticação, reserva, cadastro de arena, alternância de contexto e agenda',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Repositórios compartilhados
      final courtRepo = InMemoryCourtRepository([publicCourt]);
      final bookingRepo = FakeBookingRepository();
      final imageStorage = FakeCourtImageStorage();

      // Controladores conectados
      final auth = controllerWith();
      await auth.restoreSession();

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
        storage: imageStorage,
        onCourtMutated: () async => courtsCtrl.load(),
      );
      final ownerAgendaCtrl = ownerAgendaControllerWith(
        bookings: bookingRepo,
        now: () => agora,
      );
      final appModeCtrl = AppModeController();

      await tester.pumpWidget(
        ArenaHubApp(
          authController: auth,
          courtsController: courtsCtrl,
          bookingController: bookingCtrl,
          myBookingsController: myBookingsCtrl,
          myCourtsController: myCourtsCtrl,
          ownerAgendaController: ownerAgendaCtrl,
          appModeController: appModeCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // =======================================================================
      // 1. TELA DE LOGIN & AUTENTICAÇÃO
      // =======================================================================
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'jogador@arenahub.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'arena2026',
      );
      await tocarEm(tester, find.widgetWithText(FilledButton, 'Entrar na quadra'));

      // =======================================================================
      // 2. MODO ATLETA — CATÁLOGO E RESERVA DE HORÁRIO
      // =======================================================================
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(CourtsPage), findsOneWidget);
      expect(find.text('Olá, Craque'), findsOneWidget);
      expect(find.text('Quadras'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Quadra Pajuçara'), findsOneWidget);

      // Abre detalhes da quadra
      await tocarEm(tester, find.text('Quadra Pajuçara'));
      expect(find.byType(CourtDetailPage), findsOneWidget);

      // Escolhe amanhã (dia 29) e horário
      await tocarEm(tester, find.text('29'));
      await tocarEm(tester, find.text('10:00 – 11:00'));

      expect(find.text('Selecionado para reserva'), findsOneWidget);
      await tocarEm(tester, find.widgetWithText(FilledButton, 'Confirmar reserva'));

      // Reserva efetuada com sucesso
      expect(find.textContaining('Reserva confirmada'), findsOneWidget);

      // Volta para a lista de quadras
      await tocarEm(tester, find.byType(BackButton));
      expect(find.byType(CourtsPage), findsOneWidget);

      // Confere a reserva feita na aba Reservas
      await tocarEm(tester, find.text('Reservas'));
      expect(find.byType(MyBookingsPage), findsOneWidget);
      expect(find.text('Quadra Pajuçara'), findsOneWidget);
      expect(find.text('Beach tennis'), findsOneWidget);

      // =======================================================================
      // 3. ABA PERFIL — GATILHO CONTEXTUAL (USUÁRIO SEM QUADRAS)
      // =======================================================================
      await tocarEm(tester, find.text('Perfil'));
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Modo Atleta'), findsOneWidget);
      expect(find.text('Cadastrar Minha Arena'), findsOneWidget);
      expect(
        find.byKey(const Key('profile_add_first_court_button')),
        findsOneWidget,
      );
      // Ainda não pode alternar para proprietário
      expect(
        find.byKey(const Key('profile_switch_to_owner_button')),
        findsNothing,
      );

      // =======================================================================
      // 4. CADASTRO DA PRIMEIRA ARENA (CourtFormPage)
      // =======================================================================
      await tocarEm(tester, find.byKey(const Key('profile_add_first_court_button')));
      expect(find.byType(CourtFormPage), findsOneWidget);
      expect(find.text('Nova Quadra'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('court_name_field')),
        'Arena Central de Beach Tennis',
      );
      await tester.enterText(
        find.byKey(const Key('court_address_field')),
        'Av. Beira Mar, 250',
      );
      await tester.enterText(
        find.byKey(const Key('court_price_field')),
        '140,00',
      );

      final submitBtn = find.byKey(const Key('court_submit_button'));
      await tocarEm(tester, submitBtn);

      // Volta para a página anterior (Perfil)
      expect(find.byType(ProfilePage), findsOneWidget);

      // =======================================================================
      // 5. RECONHECIMENTO DE PROPRIETÁRIO & SWITCH DE MODO
      // =======================================================================
      // O perfil agora reconhece a nova quadra e apresenta o switch!
      expect(find.text('Sua Arena'), findsOneWidget);
      expect(find.text('1 quadra gerenciada'), findsOneWidget);
      expect(
        find.byKey(const Key('profile_switch_to_owner_button')),
        findsOneWidget,
      );

      // Alterna para o Modo Proprietário
      await tocarEm(tester, find.byKey(const Key('profile_switch_to_owner_button')));

      // =======================================================================
      // 6. MODO PROPRIETÁRIO NO HOMESHELL
      // =======================================================================
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Arena de Craque'), findsOneWidget);
      expect(find.text('PROPRIETÁRIO'), findsOneWidget);
      expect(find.text('Minhas Quadras'), findsNWidgets(2));
      expect(find.text('Perfil da Arena'), findsOneWidget);

      // A lista exibe a quadra cadastrada
      expect(find.byType(MyCourtsPage), findsOneWidget);
      expect(find.text('Arena Central de Beach Tennis'), findsOneWidget);
      expect(find.text('Av. Beira Mar, 250'), findsOneWidget);

      // =======================================================================
      // 7. CONSULTA DA AGENDA DA QUADRA DO PROPRIETÁRIO
      // =======================================================================
      await tocarEm(tester, find.text('Ver Agenda'));
      expect(find.byType(OwnerCourtAgendaPage), findsOneWidget);
      expect(find.text('Agenda da Quadra'), findsOneWidget);
      expect(find.text('Arena Central de Beach Tennis'), findsOneWidget);
      expect(find.byKey(const Key('owner_agenda_date_strip')), findsOneWidget);
      expect(find.text('Horários agendados'), findsOneWidget);
      expect(find.text('Faturamento estimado'), findsOneWidget);

      // Volta para a listagem de quadras do dono
      await tocarEm(tester, find.byType(BackButton));
      expect(find.byType(MyCourtsPage), findsOneWidget);

      // =======================================================================
      // 8. RETORNO PARA MODO ATLETA E LOGOUT
      // =======================================================================
      await tocarEm(tester, find.text('Perfil da Arena'));
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Modo Proprietário'), findsOneWidget);

      // Alterna de volta para Modo Atleta
      await tocarEm(tester, find.byKey(const Key('profile_switch_to_athlete_button')));

      // HomeShell retorna ao Modo Atleta na aba inicial (Quadras)
      expect(find.text('Olá, Craque'), findsOneWidget);
      expect(find.text('Quadras'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);

      // Navega até Perfil e realiza logout
      await tocarEm(tester, find.text('Perfil'));
      expect(find.byType(ProfilePage), findsOneWidget);
      await tocarEm(tester, find.byKey(const Key('profile_logout_button')));
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
