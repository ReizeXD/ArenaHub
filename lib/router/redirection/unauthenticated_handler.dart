import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/states/auth_state.dart';
import '../app_router.dart';
import 'redirection_handler.dart';

/// Sem login, só as telas de entrar e de cadastro ficam acessíveis.
class UnauthenticatedHandler implements RedirectionHandler {
  const UnauthenticatedHandler(this._auth);

  final AuthController _auth;

  @override
  String? redirect(String location) {
    if (_auth.state is Authenticated) {
      return null;
    }
    if (location == AppRoutes.login || location == AppRoutes.signUp) {
      return location;
    }
    return AppRoutes.login;
  }
}
