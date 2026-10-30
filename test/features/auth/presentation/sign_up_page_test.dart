import 'package:arenahub/core/failure.dart';
import 'package:arenahub/features/auth/domain/entities/role.dart';
import 'package:arenahub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:arenahub/features/auth/presentation/pages/sign_up_page.dart';
import 'package:arenahub/features/auth/presentation/widgets/social_auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../../test/support/fakes.dart';

void main() {
  Future<void> pumpSignUp(WidgetTester tester, AuthController controller) =>
      tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: controller,
          child: const MaterialApp(home: SignUpPage()),
        ),
      );

  Finder findField(int index) => find.byType(TextFormField).at(index);

  Future<void> tapSubmit(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Criar minha conta');
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets('mostra os campos de entrada, botão e link de login',
      (tester) async {
    await pumpSignUp(tester, controllerWith());

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Junte-se à comunidade do ArenaHub'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('E-mail do atleta'), findsOneWidget);
    expect(find.text('Senha de acesso'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Criar minha conta'), findsOneWidget);
    expect(find.byType(SocialAuthDivider), findsOneWidget);
    expect(find.text('ou cadastre-se com'), findsOneWidget);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.text('Cadastre-se com o Google'), findsOneWidget);
    expect(find.byType(AppleSignInButton), findsOneWidget);
    expect(find.text('Cadastre-se com a Apple'), findsOneWidget);
    expect(find.text('Já tem uma conta?'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('recusa nome incompleto sem chamar o caso de uso',
      (tester) async {
    final repository = FakeAuthRepository();
    await pumpSignUp(tester, controllerWith(repository: repository));

    await tester.enterText(findField(0), 'Carlos');
    await tester.enterText(findField(1), 'carlos@arenahub.com');
    await tester.enterText(findField(2), 'Password123');
    await tester.enterText(findField(3), 'Password123');
    await tapSubmit(tester);
    await tester.pump();

    expect(find.text('Informe o nome completo.'), findsOneWidget);
    expect(repository.signUpCalls, 0);
  });

  testWidgets('recusa e-mail inválido sem chamar o caso de uso',
      (tester) async {
    final repository = FakeAuthRepository();
    await pumpSignUp(tester, controllerWith(repository: repository));

    await tester.enterText(findField(0), 'Carlos Silva');
    await tester.enterText(findField(1), 'carlos@');
    await tester.enterText(findField(2), 'Password123');
    await tester.enterText(findField(3), 'Password123');
    await tapSubmit(tester);
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(repository.signUpCalls, 0);
  });

  testWidgets('recusa senha fraca sem chamar o caso de uso',
      (tester) async {
    final repository = FakeAuthRepository();
    await pumpSignUp(tester, controllerWith(repository: repository));

    await tester.enterText(findField(0), 'Carlos Silva');
    await tester.enterText(findField(1), 'carlos@arenahub.com');
    await tester.enterText(findField(2), '12345');
    await tester.enterText(findField(3), '12345');
    await tapSubmit(tester);
    await tester.pump();

    expect(
      find.text('A senha precisa ter ao menos 8 caracteres, com letra e número.'),
      findsOneWidget,
    );
    expect(repository.signUpCalls, 0);
  });

  testWidgets('recusa confirmação quando as senhas não coincidem',
      (tester) async {
    final repository = FakeAuthRepository();
    await pumpSignUp(tester, controllerWith(repository: repository));

    await tester.enterText(findField(0), 'Carlos Silva');
    await tester.enterText(findField(1), 'carlos@arenahub.com');
    await tester.enterText(findField(2), 'Password123');
    await tester.enterText(findField(3), 'DifferentPassword456');
    await tapSubmit(tester);
    await tester.pump();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
    expect(repository.signUpCalls, 0);
  });

  testWidgets('cadastra com sucesso chamando o repositório com Role.player',
      (tester) async {
    final repository = FakeAuthRepository();
    final controller = controllerWith(repository: repository);
    await pumpSignUp(tester, controller);

    await tester.enterText(findField(0), 'Carlos Silva');
    await tester.enterText(findField(1), 'carlos@arenahub.com');
    await tester.enterText(findField(2), 'Password123');
    await tester.enterText(findField(3), 'Password123');
    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repository.signUpCalls, 1);
    expect(controller.session, isNotNull);
    expect(controller.session!.user.fullName, 'Carlos Silva');
    expect(controller.session!.user.role, Role.player);
  });

  testWidgets('mostra a mensagem da falha quando o cadastro falha',
      (tester) async {
    final repository = FakeAuthRepository(
      failure: const EmailAlreadyInUseFailure(),
    );
    final controller = controllerWith(repository: repository);
    await pumpSignUp(tester, controller);

    await tester.enterText(findField(0), 'Carlos Silva');
    await tester.enterText(findField(1), 'carlos@arenahub.com');
    await tester.enterText(findField(2), 'Password123');
    await tester.enterText(findField(3), 'Password123');
    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
  });

  testWidgets('alterna visibilidade da senha ao clicar no ícone',
      (tester) async {
    await pumpSignUp(tester, controllerWith());

    final passwordField = tester.widget<EditableText>(
      find.descendant(
        of: findField(2),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();

    final revealedPasswordField = tester.widget<EditableText>(
      find.descendant(
        of: findField(2),
        matching: find.byType(EditableText),
      ),
    );
    expect(revealedPasswordField.obscureText, isFalse);
  });

  group('Cadastro Social', () {
    testWidgets('cadastro com Google autentica e cria sessão', (tester) async {
      final repository = FakeAuthRepository();
      final controller = controllerWith(repository: repository);
      await pumpSignUp(tester, controller);

      final googleButton = find.byType(GoogleSignInButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(repository.signInWithGoogleCalls, 1);
      expect(controller.session?.user.email, 'atleta.google@arenahub.com');
    });

    testWidgets('cadastro com Apple autentica e cria sessão', (tester) async {
      final repository = FakeAuthRepository();
      final controller = controllerWith(repository: repository);
      await pumpSignUp(tester, controller);

      final appleButton = find.byType(AppleSignInButton);
      await tester.ensureVisible(appleButton);
      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      expect(repository.signInWithAppleCalls, 1);
      expect(controller.session?.user.email, 'atleta.apple@arenahub.com');
    });

    testWidgets('quando cadastro social com Google falha, exibe SnackBar de erro',
        (tester) async {
      final repository = FakeAuthRepository(
        failure: const OAuthNetworkFailure(),
      );
      final controller = controllerWith(repository: repository);
      await pumpSignUp(tester, controller);

      final googleButton = find.byType(GoogleSignInButton);
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.text(const OAuthNetworkFailure().message), findsOneWidget);
    });
  });
}
