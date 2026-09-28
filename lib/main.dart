import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'di/auth_mode.dart';
import 'di/injector.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/states/auth_state.dart';
import 'features/courts/presentation/controllers/booking_controller.dart';
import 'features/courts/presentation/controllers/courts_controller.dart';
import 'features/courts/presentation/controllers/my_bookings_controller.dart';
import 'features/courts/presentation/pages/home_shell.dart';

/// Origem da autenticação deste build.
const AuthMode kAuthMode = AuthMode.firebase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dependências montadas uma única vez, antes do primeiro frame.
  final injector = await Injector.bootstrap(mode: kAuthMode);

  runApp(
    ArenaHubApp(
      authController: injector.authController,
      courtsController: injector.courtsController,
      bookingController: injector.bookingController,
      myBookingsController: injector.myBookingsController,
    ),
  );
}

class ArenaHubApp extends StatelessWidget {
  const ArenaHubApp({
    super.key,
    required this.authController,
    required this.courtsController,
    required this.bookingController,
    required this.myBookingsController,
  });

  final AuthController authController;
  final CourtsController courtsController;
  final BookingController bookingController;
  final MyBookingsController myBookingsController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<CourtsController>.value(value: courtsController),
        ChangeNotifierProvider<BookingController>.value(
          value: bookingController,
        ),
        ChangeNotifierProvider<MyBookingsController>.value(
          value: myBookingsController,
        ),
      ],
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
      Authenticated(:final session) => HomeShell(session: session),
      Unauthenticated() || AuthInProgress() || AuthFailed() => const LoginPage(),
    };
  }
}
