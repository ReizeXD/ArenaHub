import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/login/data/repositories/mock_login_repository_impl.dart';
import 'features/login/domain/repositories/login_repository.dart';
import 'features/login/domain/usecases/login_usecase.dart';
import 'features/login/presentation/controllers/login_controller.dart';
import 'features/login/presentation/pages/login_page.dart';

void main() {
  runApp(const ArenaHubApp());
}

class ArenaHubApp extends StatelessWidget {
  const ArenaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Injeção de dependências:
    // 1. Instanciamos a implementação do repositório (Mock)
    final ILoginRepository loginRepository = MockLoginRepositoryImpl();

    // 2. Injetamos o repositório no Caso de Uso (DIP)
    final loginUseCase = LoginUseCase(loginRepository);

    return MultiProvider(
      providers: [
        // 3. Fornecemos o LoginController para a árvore de widgets via Provider
        ChangeNotifierProvider(
          create: (_) => LoginController(loginUseCase),
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
        home: const LoginPage(),
      ),
    );
  }
}
