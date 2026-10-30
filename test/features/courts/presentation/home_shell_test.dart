import 'package:arenahub/features/auth/domain/entities/auth_session.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/domain/entities/user.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_bookings_controller.dart';
import 'package:arenahub/features/courts/presentation/controllers/my_courts_controller.dart';
import 'package:arenahub/features/courts/presentation/pages/home_shell.dart';
import 'package:arenahub/features/profile/presentation/controllers/app_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../support/court_fakes.dart';

void main() {
  const testUser = User(
    id: 'user-10',
    fullName: 'Lucas Silva',
    email: 'lucas@arenahub.com',
    role: Role.player,
  );

  final session = AuthSession(
    token: 'token-10',
    user: testUser,
    issuedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  late MyBookingsController bookingsController;
  late MyCourtsController courtsController;

  setUp(() {
    bookingsController = myBookingsControllerWith();
    courtsController = myCourtsControllerWith();
  });

  Widget buildSubject({
    required AppModeController modeController,
    String initialLocation = '/quadras',
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => HomeShell(
            session: session,
            navigationShell: shell,
            appModeController: modeController,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/quadras',
                  builder: (_, _) => const Text('Conteúdo: Quadras'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/reservas',
                  builder: (_, _) => const Text('Conteúdo: Reservas'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/perfil',
                  builder: (_, _) => const Text('Conteúdo: Perfil'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/minhas-quadras',
                  builder: (_, _) => const Text('Conteúdo: Minhas Quadras'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MyBookingsController>.value(
          value: bookingsController,
        ),
        ChangeNotifierProvider<MyCourtsController>.value(
          value: courtsController,
        ),
        ChangeNotifierProvider<AppModeController>.value(
          value: modeController,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('HomeShell — Context Switching', () {
    testWidgets('Modo Atleta exibe cabeçalho padrão e 3 abas na barra de navegação',
        (tester) async {
      final modeCtrl = AppModeController(initialMode: AppMode.athlete);

      await tester.pumpWidget(buildSubject(modeController: modeCtrl));
      await tester.pumpAndSettle();

      // Header do atleta
      expect(find.text('Olá, Lucas'), findsOneWidget);
      expect(find.text('Encontre e reserve sua quadra hoje'), findsOneWidget);
      expect(find.text('PROPRIETÁRIO'), findsNothing);

      // Abas da barra flutuante
      expect(find.text('Quadras'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Minhas Quadras'), findsNothing);

      // Conteúdo inicial (branch 0)
      expect(find.text('Conteúdo: Quadras'), findsOneWidget);

      // Toca em Reservas (branch 1)
      await tester.tap(find.text('Reservas'));
      await tester.pumpAndSettle();

      expect(find.text('Conteúdo: Reservas'), findsOneWidget);
      expect(find.text('Seus horários reservados'), findsOneWidget);

      // Toca em Perfil (branch 2)
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Conteúdo: Perfil'), findsOneWidget);
      expect(find.text('Gerencie sua conta e modo de uso'), findsOneWidget);
    });

    testWidgets('Modo Proprietário exibe badge no cabeçalho e 2 abas na barra de navegação',
        (tester) async {
      final modeCtrl = AppModeController(initialMode: AppMode.owner);

      await tester.pumpWidget(
        buildSubject(
          modeController: modeCtrl,
          initialLocation: '/minhas-quadras',
        ),
      );
      await tester.pumpAndSettle();

      // Header do proprietário com badge destacado
      expect(find.text('Arena de Lucas'), findsOneWidget);
      expect(find.text('PROPRIETÁRIO'), findsOneWidget);
      expect(find.text('Gerenciamento de quadras da arena'), findsOneWidget);

      // Abas da barra flutuante do proprietário
      expect(find.text('Minhas Quadras'), findsOneWidget);
      expect(find.text('Perfil da Arena'), findsOneWidget);
      expect(find.text('Quadras'), findsNothing);
      expect(find.text('Reservas'), findsNothing);

      // Conteúdo inicial (branch 3)
      expect(find.text('Conteúdo: Minhas Quadras'), findsOneWidget);

      // Toca em Perfil da Arena (branch 2)
      await tester.tap(find.text('Perfil da Arena'));
      await tester.pumpAndSettle();

      expect(find.text('Conteúdo: Perfil'), findsOneWidget);
      expect(find.text('Perfil e configurações da arena'), findsOneWidget);
    });

    testWidgets('ao alternar modo de atleta para proprietário, reseta para branch 3 e atualiza UI',
        (tester) async {
      final modeCtrl = AppModeController(initialMode: AppMode.athlete);

      await tester.pumpWidget(buildSubject(modeController: modeCtrl));
      await tester.pumpAndSettle();

      expect(find.text('Olá, Lucas'), findsOneWidget);
      expect(find.text('Conteúdo: Quadras'), findsOneWidget);

      // Alterna o contexto para proprietário
      modeCtrl.setMode(AppMode.owner);
      await tester.pumpAndSettle();

      // Deve resetar para a primeira aba do dono (branch 3: /minhas-quadras)
      expect(find.text('Conteúdo: Minhas Quadras'), findsOneWidget);
      expect(find.text('Arena de Lucas'), findsOneWidget);
      expect(find.text('PROPRIETÁRIO'), findsOneWidget);
      expect(find.text('Minhas Quadras'), findsOneWidget);
      expect(find.text('Perfil da Arena'), findsOneWidget);
    });

    testWidgets('ao alternar modo de proprietário para atleta, reseta para branch 0 e restaura UI',
        (tester) async {
      final modeCtrl = AppModeController(initialMode: AppMode.owner);

      await tester.pumpWidget(
        buildSubject(
          modeController: modeCtrl,
          initialLocation: '/minhas-quadras',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arena de Lucas'), findsOneWidget);
      expect(find.text('Conteúdo: Minhas Quadras'), findsOneWidget);

      // Alterna o contexto de volta para atleta
      modeCtrl.setMode(AppMode.athlete);
      await tester.pumpAndSettle();

      // Deve resetar para a primeira aba do atleta (branch 0: /quadras)
      expect(find.text('Conteúdo: Quadras'), findsOneWidget);
      expect(find.text('Olá, Lucas'), findsOneWidget);
      expect(find.text('Quadras'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });
  });
}
