import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:arenahub/features/auth/presentation/pages/login_page.dart';
import 'package:arenahub/features/auth/presentation/widgets/social_auth_widgets.dart';
import 'package:arenahub/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/fakes.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, AuthController controller) =>
      tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginPage(),
          ),
        ),
      );

  group('LoginPage — Componentes de Login Social', () {
    testWidgets('exibe divisor e botões sociais do Google e Apple', (tester) async {
      final controller = controllerWith();
      await pumpLogin(tester, controller);

      expect(find.byType(SocialAuthDivider), findsOneWidget);
      expect(find.text('ou continue com'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(find.byType(AppleSignInButton), findsOneWidget);
      expect(find.text('Continuar com a Apple'), findsOneWidget);
    });

    testWidgets('clique no botão do Google dispara signInWithGoogle e autentica',
        (tester) async {
      final repository = FakeAuthRepository();
      final controller = controllerWith(repository: repository);
      await pumpLogin(tester, controller);

      final googleButton = find.byType(GoogleSignInButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(repository.signInWithGoogleCalls, 1);
      expect(controller.session?.user.email, 'atleta.google@arenahub.com');
    });

    testWidgets('clique no botão da Apple dispara signInWithApple e autentica',
        (tester) async {
      final repository = FakeAuthRepository();
      final controller = controllerWith(repository: repository);
      await pumpLogin(tester, controller);

      final appleButton = find.byType(AppleSignInButton);
      await tester.ensureVisible(appleButton);
      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      expect(repository.signInWithAppleCalls, 1);
      expect(controller.session?.user.email, 'atleta.apple@arenahub.com');
    });

    testWidgets('quando login social com Google falha, exibe SnackBar de erro',
        (tester) async {
      final repository = FakeAuthRepository(
        failure: const OAuthAccountCollisionFailure(),
      );
      final controller = controllerWith(repository: repository);
      await pumpLogin(tester, controller);

      final googleButton = find.byType(GoogleSignInButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(
        find.text(const OAuthAccountCollisionFailure().message),
        findsOneWidget,
      );
    });

    testWidgets('quando login social é cancelado pelo usuário, não exibe SnackBar',
        (tester) async {
      final repository = FakeAuthRepository(
        failure: const OAuthCancelledFailure(),
      );
      final controller = controllerWith(repository: repository);
      await pumpLogin(tester, controller);

      final googleButton = find.byType(GoogleSignInButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
