import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'di/auth_mode.dart';
import 'di/injector.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/courts/presentation/controllers/booking_controller.dart';
import 'features/courts/presentation/controllers/courts_controller.dart';
import 'features/courts/presentation/controllers/my_bookings_controller.dart';
import 'features/courts/presentation/controllers/my_courts_controller.dart';
import 'features/courts/presentation/controllers/owner_agenda_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

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
      myCourtsController: injector.myCourtsController,
      ownerAgendaController: injector.ownerAgendaController,
    ),
  );
}

class ArenaHubApp extends StatefulWidget {
  const ArenaHubApp({
    super.key,
    required this.authController,
    required this.courtsController,
    required this.bookingController,
    required this.myBookingsController,
    this.myCourtsController,
    this.ownerAgendaController,
  });

  final AuthController authController;
  final CourtsController courtsController;
  final BookingController bookingController;
  final MyBookingsController myBookingsController;
  final MyCourtsController? myCourtsController;
  final OwnerAgendaController? ownerAgendaController;

  @override
  State<ArenaHubApp> createState() => _ArenaHubAppState();
}

class _ArenaHubAppState extends State<ArenaHubApp> {
  late final GoRouter _router = buildAppRouter(
    auth: widget.authController,
    courts: widget.courtsController,
    myCourts: widget.myCourtsController,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(
          value: widget.authController,
        ),
        ChangeNotifierProvider<CourtsController>.value(
          value: widget.courtsController,
        ),
        ChangeNotifierProvider<BookingController>.value(
          value: widget.bookingController,
        ),
        ChangeNotifierProvider<MyBookingsController>.value(
          value: widget.myBookingsController,
        ),
        if (widget.myCourtsController != null)
          ChangeNotifierProvider<MyCourtsController>.value(
            value: widget.myCourtsController!,
          ),
        if (widget.ownerAgendaController != null)
          ChangeNotifierProvider<OwnerAgendaController>.value(
            value: widget.ownerAgendaController!,
          ),
      ],
      child: MaterialApp.router(
        title: 'ArenaHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
