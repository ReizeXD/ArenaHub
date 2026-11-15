import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/states/auth_state.dart';
import '../app_router.dart';
import 'redirection_handler.dart';

/// Enquanto a sessão salva é verificada, segura o usuário no splash.
class SessionCheckingHandler implements RedirectionHandler {
  const SessionCheckingHandler(this._auth);

  final AuthController _auth;

  @override
  String? redirect(String location) =>
      _auth.state is AuthChecking ? AppRoutes.splash : null;
}
