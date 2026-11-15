/// Uma regra de navegação na cadeia de redirecionamento (Chain of Responsibility).
abstract interface class RedirectionHandler {
  /// Rota de destino, a própria [location] para encerrar a cadeia ali,
  /// ou `null` para deixar o próximo handler decidir.
  String? redirect(String location);
}
