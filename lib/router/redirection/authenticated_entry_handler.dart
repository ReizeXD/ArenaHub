import '../app_router.dart';
import 'redirection_handler.dart';

/// Quem já está logado não volta para splash, login ou cadastro.
class AuthenticatedEntryHandler implements RedirectionHandler {
  const AuthenticatedEntryHandler();

  static const _entryRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.signUp,
  };

  @override
  String? redirect(String location) =>
      _entryRoutes.contains(location) ? AppRoutes.courts : null;
}
