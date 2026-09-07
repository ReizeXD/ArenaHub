import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/datasources/firestore_user_profile_data_source.dart';
import '../features/auth/data/datasources/in_memory_user_data_source.dart';
import '../features/auth/data/datasources/sqflite_user_data_source.dart';
import '../features/auth/data/datasources/user_data_source.dart';
import '../features/auth/data/repositories/firebase_auth_repository.dart';
import '../features/auth/data/repositories/local_auth_repository.dart';
import '../features/auth/data/seed/demo_user_seeder.dart';
import '../features/auth/data/services/pbkdf2_password_hasher.dart';
import '../features/auth/data/services/prefs_session_storage.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/services/session_storage.dart';
import '../features/auth/domain/usecases/get_current_session.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../firebase_options.dart';
import 'auth_mode.dart';

/// Composition root: o **único** ponto do app que menciona classes concretas.
///
/// Repare no `switch` de [_buildRepository]: é o projeto inteiro trocando de
/// backend de autenticação em uma expressão. Nenhuma tela, caso de uso ou
/// entidade sabe que essa escolha existe.
class Injector {
  const Injector._(this.authController);

  final AuthController authController;

  static Future<Injector> bootstrap({AuthMode mode = AuthMode.local}) async {
    final preferences = await SharedPreferences.getInstance();
    final SessionStorage sessionStorage = PrefsSessionStorage(preferences);

    final AuthRepository authRepository = await _buildRepository(mode);

    final controller = AuthController(
      SignIn(authRepository, sessionStorage),
      SignUp(authRepository, sessionStorage),
      SignOut(sessionStorage),
      GetCurrentSession(sessionStorage),
    );
    await controller.restoreSession();

    return Injector._(controller);
  }

  static Future<AuthRepository> _buildRepository(AuthMode mode) async =>
      switch (mode) {
        AuthMode.local => _buildLocalRepository(),
        AuthMode.firebase => _buildFirebaseRepository(),
      };

  static Future<AuthRepository> _buildLocalRepository() async {
    final passwordHasher = Pbkdf2PasswordHasher();
    final UserDataSource userDataSource = await _openUserDataSource();

    // Contas de demonstração só fazem sentido no modo local; no Firebase os
    // usuários são criados pelo cadastro ou pelo console.
    await DemoUserSeeder(userDataSource, passwordHasher).seed();

    return LocalAuthRepository(userDataSource, passwordHasher);
  }

  static Future<AuthRepository> _buildFirebaseRepository() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    return FirebaseAuthRepository(
      fb.FirebaseAuth.instance,
      FirestoreUserProfileDataSource(FirebaseFirestore.instance),
    );
  }

  /// SQLite no aparelho; em memória na web, onde o plugin nativo não existe.
  static Future<UserDataSource> _openUserDataSource() async =>
      kIsWeb ? InMemoryUserDataSource() : await SqfliteUserDataSource.open();
}
