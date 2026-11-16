import 'package:arenahub/router/app_router.dart';
import 'package:arenahub/router/redirection/authenticated_entry_handler.dart';
import 'package:arenahub/router/redirection/redirection_handler.dart';
import 'package:arenahub/router/redirection/redirection_middleware.dart';
import 'package:arenahub/router/redirection/session_checking_handler.dart';
import 'package:arenahub/router/redirection/unauthenticated_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  group('SessionCheckingHandler', () {
    test('segura no splash enquanto verifica a sessão', () {
      final handler = SessionCheckingHandler(controllerWith());

      expect(handler.redirect(AppRoutes.courts), AppRoutes.splash);
    });

    test('depois da verificação, deixa o próximo decidir', () async {
      final auth = controllerWith();
      await auth.restoreSession();

      expect(SessionCheckingHandler(auth).redirect(AppRoutes.courts), isNull);
    });
  });

  group('UnauthenticatedHandler', () {
    test('sem login, manda as rotas protegidas para o login', () async {
      final auth = controllerWith();
      await auth.restoreSession();

      expect(
        UnauthenticatedHandler(auth).redirect(AppRoutes.courts),
        AppRoutes.login,
      );
    });

    test('sem login, encerra a cadeia em login e cadastro', () async {
      final auth = controllerWith();
      await auth.restoreSession();
      final handler = UnauthenticatedHandler(auth);

      expect(handler.redirect(AppRoutes.login), AppRoutes.login);
      expect(handler.redirect(AppRoutes.signUp), AppRoutes.signUp);
    });

    test('logado, deixa o próximo decidir', () async {
      final storage = InMemorySessionStorage()
        ..seed(FakeAuthRepository.sessionFor('jogador@arenahub.com'));
      final auth = controllerWith(storage: storage);
      await auth.restoreSession();

      expect(UnauthenticatedHandler(auth).redirect(AppRoutes.courts), isNull);
    });
  });

  group('AuthenticatedEntryHandler', () {
    const handler = AuthenticatedEntryHandler();

    test('tira o usuário logado das telas de entrada', () {
      expect(handler.redirect(AppRoutes.login), AppRoutes.courts);
      expect(handler.redirect(AppRoutes.signUp), AppRoutes.courts);
      expect(handler.redirect(AppRoutes.splash), AppRoutes.courts);
    });

    test('não interfere nas demais rotas', () {
      expect(handler.redirect(AppRoutes.bookings), isNull);
    });
  });

  group('RedirectionMiddleware', () {
    test('o primeiro handler que decide encerra a cadeia', () {
      final second = _SpyHandler('/b');
      final middleware = RedirectionMiddleware([_SpyHandler('/a'), second]);

      expect(middleware.handle('/x'), '/a');
      expect(second.calls, 0, reason: 'short-circuit');
    });

    test('null passa para o próximo', () {
      final middleware = RedirectionMiddleware([
        _SpyHandler(null),
        _SpyHandler('/b'),
      ]);

      expect(middleware.handle('/x'), '/b');
    });

    test('devolver a própria rota encerra a cadeia sem redirecionar', () {
      final second = _SpyHandler('/b');
      final middleware = RedirectionMiddleware([_SpyHandler('/x'), second]);

      expect(middleware.handle('/x'), isNull);
      expect(second.calls, 0);
    });

    test('ninguém decide: segue a navegação', () {
      expect(RedirectionMiddleware([_SpyHandler(null)]).handle('/x'), isNull);
    });
  });
}

class _SpyHandler implements RedirectionHandler {
  _SpyHandler(this._result);

  final String? _result;
  int calls = 0;

  @override
  String? redirect(String location) {
    calls++;
    return _result;
  }
}
