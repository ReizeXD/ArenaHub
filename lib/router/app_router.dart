import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/states/auth_state.dart';
import '../features/courts/domain/entities/court.dart';
import '../features/courts/presentation/controllers/courts_controller.dart';
import '../features/courts/presentation/controllers/my_courts_controller.dart';
import '../features/courts/presentation/pages/court_detail_page.dart';
import '../features/courts/presentation/pages/court_form_page.dart';
import '../features/courts/presentation/pages/courts_page.dart';
import '../features/courts/presentation/pages/home_shell.dart';
import '../features/courts/presentation/pages/my_bookings_page.dart';
import '../features/courts/presentation/pages/my_courts_page.dart';
import '../features/courts/presentation/pages/owner_court_agenda_page.dart';
import '../features/courts/presentation/states/courts_state.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/signup';
  static const courts = '/courts';
  static const bookings = '/bookings';
  static const profile = '/profile';
  static const myCourts = '/my-courts';
  static const myCourtsNew = '/my-courts/new';

  static String court(String id) => '$courts/$id';
  static String myCourtEdit(String id) => '$myCourts/$id/edit';
  static String myCourtAgenda(String id) => '$myCourts/$id/agenda';
}

GoRouter buildAppRouter({
  required AuthController auth,
  required CourtsController courts,
  MyCourtsController? myCourts,
}) {
  final rootKey = GlobalKey<NavigatorState>();

  Court? courtFor(GoRouterState state) {
    if (state.extra case final Court court) return court;
    final id = state.pathParameters['courtId'];
    if (id == null) return null;

    if (myCourts != null) {
      final ownerMatch =
          myCourts.courts.where((court) => court.id == id).firstOrNull;
      if (ownerMatch != null) return ownerMatch;
    }

    return switch (courts.state) {
      CourtsLoaded(courts: final list) =>
        list.where((court) => court.id == id).firstOrNull,
      _ => null,
    };
  }

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.courts,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (auth.state is AuthChecking) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (auth.state is! Authenticated) {
        final isAuthRoute =
            location == AppRoutes.login || location == AppRoutes.signUp;
        return isAuthRoute ? null : AppRoutes.login;
      }
      if (location == AppRoutes.login ||
          location == AppRoutes.signUp ||
          location == AppRoutes.splash) {
        return AppRoutes.courts;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            HomeShell(session: auth.session!, navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.courts,
                builder: (_, _) => const CourtsPage(),
                routes: [
                  GoRoute(
                    path: ':courtId',
                    parentNavigatorKey: rootKey,
                    redirect: (_, state) =>
                        courtFor(state) == null ? AppRoutes.courts : null,
                    builder: (_, state) =>
                        CourtDetailPage(court: courtFor(state)!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookings,
                builder: (_, _) => MyBookingsPage(session: auth.session!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myCourts,
        parentNavigatorKey: rootKey,
        builder: (context, state) => MyCourtsPage(
          ownerId: auth.session!.user.id,
          onViewCourtAgenda: (court) => context.push(
            AppRoutes.myCourtAgenda(court.id),
            extra: court,
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            builder: (context, state) => CourtFormPage(
              ownerId: auth.session!.user.id,
            ),
          ),
          GoRoute(
            path: ':courtId/edit',
            parentNavigatorKey: rootKey,
            redirect: (_, state) =>
                courtFor(state) == null ? AppRoutes.myCourts : null,
            builder: (context, state) => CourtFormPage(
              ownerId: auth.session!.user.id,
              courtToEdit: courtFor(state)!,
            ),
          ),
          GoRoute(
            path: ':courtId/agenda',
            parentNavigatorKey: rootKey,
            redirect: (_, state) =>
                courtFor(state) == null ? AppRoutes.myCourts : null,
            builder: (context, state) => OwnerCourtAgendaPage(
              court: courtFor(state)!,
              ownerId: auth.session!.user.id,
            ),
          ),
        ],
      ),
    ],
  );
}
