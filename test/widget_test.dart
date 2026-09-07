import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:arenahub/features/auth/presentation/pages/login_page.dart';
import 'package:arenahub/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, AuthController controller) =>
      tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: const MaterialApp(home: LoginPage()),
        ),
      );

  testWidgets('mostra os campos de entrada', (tester) async {
    await pumpLogin(tester, controllerWith());

    expect(find.text('ArenaHub'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('recusa e-mail inválido sem chamar o caso de uso',
      (tester) async {
    final repository = FakeAuthRepository();
    await pumpLogin(tester, controllerWith(repository: repository));

    await tester.enterText(find.byType(TextFormField).first, 'jogador@');
    await tester.enterText(find.byType(TextFormField).last, 'arena2026');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pump();

    // A mensagem vem do value object Email, não de uma regra reescrita na tela.
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('mostra a mensagem da falha quando as credenciais não batem',
      (tester) async {
    await pumpLogin(
      tester,
      controllerWith(
        repository: FakeAuthRepository(
          failure: const InvalidCredentialsFailure(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'jogador@arenahub.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'senhaerrada1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('o gate troca de tela conforme o estado da autenticação',
      (tester) async {
    final controller = controllerWith();
    await controller.restoreSession();

    await tester.pumpWidget(ArenaHubApp(authController: controller));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'jogador@arenahub.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'arena2026');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Bem-vindo, Craque!'), findsOneWidget);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
