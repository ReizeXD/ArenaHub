import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/entities/user.dart';
import 'package:arenahub/features/courts/data/repositories/in_memory_court_repository.dart';
import 'package:arenahub/features/courts/domain/entities/court.dart';
import 'package:arenahub/features/courts/domain/entities/sport.dart';
import 'package:arenahub/features/profile/presentation/controllers/app_mode_controller.dart';
import 'package:arenahub/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/court_fakes.dart';

void main() {
  const testUser = User(
    id: 'user-42',
    fullName: 'Felipe Alcantara',
    email: 'felipe@arenahub.com',
    role: Role.player,
  );

  final session = AuthSession(
    token: 'token-42',
    user: testUser,
    issuedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  const sampleCourt = Court(
    id: 'court-1',
    ownerId: 'user-42',
    name: 'Arena Sol e Areia',
    sport: Sport.beachTennis,
    address: 'Av. Beira Mar, 50',
    pricePerHourInCents: 10000,
    openingHour: 8,
    closingHour: 22,
  );

  group('ProfilePage', () {
    testWidgets('exibe dados do usuário logado (iniciais, nome, e-mail e badge)',
        (tester) async {
      final myCourts = myCourtsControllerWith(
        courts: InMemoryCourtRepository([]),
      );
      final modeCtrl = AppModeController();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            session: session,
            appModeController: modeCtrl,
            myCourtsController: myCourts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('FA'), findsOneWidget); // Iniciais de Felipe Alcantara
      expect(find.text('Felipe Alcantara'), findsOneWidget);
      expect(find.text('felipe@arenahub.com'), findsOneWidget);
      expect(find.text('Modo Atleta'), findsOneWidget);
    });

    testWidgets('quando o usuário não possui quadras, exibe banner CTA para cadastrar arena',
        (tester) async {
      var addCourtClicked = false;
      final emptyRepo = InMemoryCourtRepository([]);
      final myCourts = myCourtsControllerWith(courts: emptyRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            session: session,
            myCourtsController: myCourts,
            onAddCourt: () => addCourtClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confere exibição do banner CTA
      expect(find.text('Cadastrar minha arena'), findsOneWidget);
      expect(
        find.text(
          'Você ainda não possui quadras cadastradas. Torne-se um parceiro do ArenaHub e gerencie horários e faturamento diretamente pelo app!',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile_add_first_court_button')),
        findsOneWidget,
      );

      // Não deve exibir botão de alternar para proprietário
      expect(
        find.byKey(const Key('profile_switch_to_owner_button')),
        findsNothing,
      );

      // Toca no botão
      await tester.tap(find.byKey(const Key('profile_add_first_court_button')));
      await tester.pump();

      expect(addCourtClicked, isTrue);
    });

    testWidgets('quando o usuário já possui quadras, exibe status da arena e botão para alternar de modo',
        (tester) async {
      var switchedToOwner = false;
      final repoWithCourt = InMemoryCourtRepository([sampleCourt]);
      final myCourts = myCourtsControllerWith(courts: repoWithCourt);
      final modeCtrl = AppModeController(initialMode: AppMode.athlete);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            session: session,
            appModeController: modeCtrl,
            myCourtsController: myCourts,
            onSwitchToOwner: () => switchedToOwner = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner CTA vazio não deve aparecer
      expect(
        find.byKey(const Key('profile_add_first_court_button')),
        findsNothing,
      );

      // Card de status da arena deve aparecer
      expect(find.text('Sua Arena'), findsOneWidget);
      expect(find.text('1 quadra gerenciada'), findsOneWidget);

      // Botão para alternar para modo proprietário
      expect(
        find.byKey(const Key('profile_switch_to_owner_button')),
        findsOneWidget,
      );
      expect(find.text('Alternar para Modo Proprietário'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_switch_to_owner_button')));
      await tester.pump();

      expect(switchedToOwner, isTrue);
    });

    testWidgets('no modo proprietário, exibe opção para voltar ao modo atleta',
        (tester) async {
      var switchedToAthlete = false;
      final repoWithCourt = InMemoryCourtRepository([sampleCourt]);
      final myCourts = myCourtsControllerWith(courts: repoWithCourt);
      final modeCtrl = AppModeController(initialMode: AppMode.owner);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            session: session,
            appModeController: modeCtrl,
            myCourtsController: myCourts,
            onSwitchToAthlete: () => switchedToAthlete = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge deve refletir modo proprietário
      expect(find.text('Modo Proprietário'), findsOneWidget);

      // Botão para voltar ao modo atleta
      expect(
        find.byKey(const Key('profile_switch_to_athlete_button')),
        findsOneWidget,
      );
      expect(find.text('Alternar para Modo Atleta'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_switch_to_athlete_button')));
      await tester.pump();

      expect(switchedToAthlete, isTrue);
    });

    testWidgets('ao clicar em Sair da conta, invoca callback de sign out',
        (tester) async {
      var signOutClicked = false;
      final myCourts = myCourtsControllerWith(
        courts: InMemoryCourtRepository([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            session: session,
            myCourtsController: myCourts,
            onSignOut: () => signOutClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const Key('profile_logout_button'));
      expect(logoutBtn, findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pump();

      expect(signOutClicked, isTrue);
    });
  });
}
