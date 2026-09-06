import 'failure.dart';

/// Resultado explícito de uma operação: sucesso com valor ou falha tipada.
///
/// Substitui o par `throw Exception(...)` / `catch` no fluxo de negócio. A
/// diferença prática: o compilador obriga quem chama a tratar os dois casos,
/// e a falha chega como tipo, não como texto a ser interpretado.
sealed class Result<T> {
  const Result();

  /// Reduz os dois casos a um único valor, sem `is`/cast no chamador.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  });

  bool get isSuccess => this is Ok<T>;
  bool get isFailure => this is Err<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      onSuccess(value);
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      onFailure(failure);

  /// Repropaga a mesma falha em outro tipo de resultado.
  Err<R> cast<R>() => Err<R>(failure);
}
