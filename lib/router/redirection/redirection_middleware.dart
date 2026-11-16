import 'redirection_handler.dart';

/// Percorre os handlers em ordem; o primeiro que decidir encerra a cadeia.
class RedirectionMiddleware {
  const RedirectionMiddleware(this._handlers);

  final List<RedirectionHandler> _handlers;

  String? handle(String location) {
    for (final handler in _handlers) {
      final result = handler.redirect(location);
      if (result != null) return result == location ? null : result;
    }
    return null;
  }
}
