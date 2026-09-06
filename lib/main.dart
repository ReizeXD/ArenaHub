import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/auth_mode.dart';
import 'di/injector.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/states/auth_state.dart';
import 'features/home/presentation/pages/home_page.dart';

/// Origem da autenticação deste build.
///
/// Trocar esta constante troca o backend inteiro de autenticação — é o
/// resultado prático de todo o resto do app depender só de abstrações.
/// `AuthMode.firebase` exige ter rodado `flutterfire configure`.
const AuthMode kAuthMode = AuthMode.local;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependências montadas uma única vez, antes do primeiro frame.
  final injector = await Injector.bootstrap(mode: kAuthMode);

  runApp(ArenaHubApp(authController: injector.authController));
}

class ArenaHubApp extends StatelessWidget {
  const ArenaHubApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>.value(
      value: authController,
      child: MaterialApp(
        title: 'ArenaHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Roboto',
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qual tela mostrar a partir do estado da autenticação.
///
/// Centralizar a navegação aqui evita que cada tela conheça a próxima: a
/// `LoginPage` não importa a `HomePage`, e vice-versa.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthController>().state;

    return switch (state) {
      AuthChecking() => const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        ),
      Authenticated(:final session) => HomePage(session: session),
      Unauthenticated() || AuthInProgress() || AuthFailed() => const LoginPage(),
    };
  }
}
