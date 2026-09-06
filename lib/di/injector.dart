import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/datasources/in_memory_user_data_source.dart';
import '../features/auth/data/datasources/sqflite_user_data_source.dart';
import '../features/auth/data/datasources/user_data_source.dart';
import '../features/auth/data/repositories/local_auth_repository.dart';
import '../features/auth/data/seed/demo_user_seeder.dart';
import '../features/auth/data/services/pbkdf2_password_hasher.dart';
import '../features/auth/data/services/prefs_session_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/services/password_hasher.dart';
import '../features/auth/domain/services/session_storage.dart';
import '../features/auth/domain/usecases/get_current_session.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

/// Composition root: o **único** ponto do app que menciona classes concretas.
///
/// Todo o resto — telas, casos de uso, entidades — conhece apenas
/// abstrações. Trocar SQLite por outro banco, ou o adaptador local por um
/// cliente HTTP, é editar este arquivo e mais nenhum.
///
/// Fica fora do `build` de propósito: montado uma vez, antes do primeiro
/// frame, em vez de reconstruído a cada rebuild da árvore de widgets.
class Injector {
  const Injector._(this.authController);

  final AuthController authController;

  static Future<Injector> bootstrap() async {
    final preferences = await SharedPreferences.getInstance();
    final SessionStorage sessionStorage = PrefsSessionStorage(preferences);

    final PasswordHasher passwordHasher = Pbkdf2PasswordHasher();
    final UserDataSource userDataSource = await _openUserDataSource();

    await DemoUserSeeder(userDataSource, passwordHasher).seed();

    final AuthRepository authRepository =
        LocalAuthRepository(userDataSource, passwordHasher);

    final controller = AuthController(
      SignIn(authRepository, sessionStorage),
      SignUp(authRepository, sessionStorage),
      SignOut(sessionStorage),
      GetCurrentSession(sessionStorage),
    );
    await controller.restoreSession();

    return Injector._(controller);
  }

  /// SQLite no aparelho; em memória na web, onde o plugin nativo não existe.
  static Future<UserDataSource> _openUserDataSource() async =>
      kIsWeb ? InMemoryUserDataSource() : await SqfliteUserDataSource.open();
}
