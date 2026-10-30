import 'package:arenahub/features/auth/presentation/widgets/social_auth_widgets.dart';
import 'package:arenahub/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testBoilerplate({required Widget child, Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: AppTheme.light.copyWith(brightness: brightness),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('SocialAuthDivider', () {
    testWidgets('renderiza texto padrão "ou continue com" e divisores', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(child: const SocialAuthDivider()),
      );

      expect(find.text('ou continue com'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('renderiza texto customizado quando fornecido', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          child: const SocialAuthDivider(label: 'ou acesse com sua conta'),
        ),
      );

      expect(find.text('ou acesse com sua conta'), findsOneWidget);
    });
  });

  group('GoogleLogo', () {
    testWidgets('renderiza CustomPaint com dimensões corretas', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(child: const GoogleLogo(size: 24)),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      final size = tester.getSize(find.byType(GoogleLogo));
      expect(size.width, 24);
      expect(size.height, 24);
    });
  });

  group('SocialAuthButton', () {
    testWidgets('renderiza ícone, texto e responde ao toque', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testBoilerplate(
          child: SocialAuthButton(
            onPressed: () => tapped = true,
            icon: const Icon(Icons.star),
            label: 'Botão de Teste',
          ),
        ),
      );

      expect(find.text('Botão de Teste'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Botão de Teste'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('quando em loading exibe spinner e bloqueia cliques', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testBoilerplate(
          child: SocialAuthButton(
            onPressed: () => tapped = true,
            icon: const Icon(Icons.star),
            label: 'Botão de Teste',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);

      await tester.tap(find.byType(SocialAuthButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('quando desabilitado (onPressed nulo) não dispara callback', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          child: const SocialAuthButton(
            onPressed: null,
            icon: Icon(Icons.star),
            label: 'Desabilitado',
          ),
        ),
      );

      expect(find.text('Desabilitado'), findsOneWidget);
      await tester.tap(find.text('Desabilitado'));
      await tester.pump();
    });
  });

  group('GoogleSignInButton', () {
    testWidgets('renderiza texto padrão e ícone do Google', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        testBoilerplate(
          child: GoogleSignInButton(
            onPressed: () => clicked = true,
          ),
        ),
      );

      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);

      await tester.tap(find.text('Continuar com o Google'));
      await tester.pump();

      expect(clicked, isTrue);
    });

    testWidgets('renderiza estado de loading corretamente', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          child: GoogleSignInButton(
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GoogleLogo), findsNothing);
    });

    testWidgets('adapta cores no modo escuro', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          brightness: Brightness.dark,
          child: GoogleSignInButton(
            onPressed: () {},
            darkMode: true,
          ),
        ),
      );

      expect(find.text('Continuar com o Google'), findsOneWidget);
    });
  });

  group('AppleSignInButton', () {
    testWidgets('renderiza texto padrão e ícone da Apple', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        testBoilerplate(
          child: AppleSignInButton(
            onPressed: () => clicked = true,
          ),
        ),
      );

      expect(find.text('Continuar com a Apple'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);

      await tester.tap(find.text('Continuar com a Apple'));
      await tester.pump();

      expect(clicked, isTrue);
    });

    testWidgets('renderiza estado de loading corretamente', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          child: AppleSignInButton(
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsNothing);
    });

    testWidgets('quando isAvailable for false não renderiza nada', (tester) async {
      await tester.pumpWidget(
        testBoilerplate(
          child: AppleSignInButton(
            onPressed: () {},
            isAvailable: false,
          ),
        ),
      );

      expect(find.text('Continuar com a Apple'), findsNothing);
      expect(find.byType(SocialAuthButton), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('isSupportedOnCurrentPlatform retorna valor booleano', (tester) async {
      final isSupported = AppleSignInButton.isSupportedOnCurrentPlatform();
      expect(isSupported, isA<bool>());
    });
  });
}
