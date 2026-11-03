// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/role.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../states/auth_state.dart';

/// Liga a interface aos casos de uso.
class AuthController extends ChangeNotifier {
  AuthController(
    this._signIn,
    this._signUp,
    this._signOut,
    this._getCurrentSession, {
    SignInWithGoogle? signInWithGoogle,
    SignInWithApple? signInWithApple,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple;

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentSession _getCurrentSession;
  final SignInWithGoogle? _signInWithGoogle;
  final SignInWithApple? _signInWithApple;

  AuthState _state = const AuthChecking();
  AuthState get state => _state;

  /// Sessão ativa, quando houver.
  AuthSession? get session =>
      _state is Authenticated ? (_state as Authenticated).session : null;

  /// Chamado na abertura do app: restaura a sessão salva, se houver.
  Future<void> restoreSession() async {
    _emit(const AuthChecking());
    final session = await _getCurrentSession();
    _emit(session == null ? const Unauthenticated() : Authenticated(session));
  }

  Future<void> signIn({required String email, required String password}) async {
    _emit(const AuthInProgress());
    _emitResult(await _signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required Role role,
  }) async {
    _emit(const AuthInProgress());
    _emitResult(
      await _signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    final useCase = _signInWithGoogle;
    if (useCase == null) return;

    _emit(const AuthInProgress());
    _handleSocialResult(await useCase());
  }

  Future<void> signInWithApple() async {
    final useCase = _signInWithApple;
    if (useCase == null) return;

    _emit(const AuthInProgress());
    _handleSocialResult(await useCase());
  }

  Future<void> signOut() async {
    await _signOut();
    _emit(const Unauthenticated());
  }

  /// Limpa a mensagem de erro sem perder o que o usuário digitou.
  void dismissError() {
    if (_state is AuthFailed) _emit(const Unauthenticated());
  }

  void _handleSocialResult(Result<AuthSession> result) {
    result.fold(
      onSuccess: (session) => _emit(Authenticated(session)),
      onFailure: (failure) {
        if (failure is OAuthCancelledFailure) {
          _emit(const Unauthenticated());
        } else {
          _emit(AuthFailed(failure));
        }
      },
    );
  }

  void _emitResult(Result<AuthSession> result) => _emit(
        result.fold(
          onSuccess: Authenticated.new,
          onFailure: AuthFailed.new,
        ),
      );

  void _emit(AuthState next) {
    _state = next;
    notifyListeners();
  }
}
