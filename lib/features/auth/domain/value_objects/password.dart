import '../../../../core/failure.dart';
import '../../../../core/result.dart';

/// Senha em texto puro, já validada quanto à força mínima.
///
/// Só transita entre a tela e o adaptador que sabe transformá-la em hash;
/// nunca é persistida nem colocada dentro de uma entidade de domínio. O
/// `toString` mascarado evita que ela vaze em log ou mensagem de erro.
class Password {
  const Password._(this.value);

  final String value;

  static const int minLength = 8;

  static Result<Password> create(String raw) {
    final hasMinLength = raw.length >= minLength;
    final hasLetter = raw.contains(RegExp(r'[A-Za-zÀ-ÿ]'));
    final hasDigit = raw.contains(RegExp(r'\d'));

    if (!hasMinLength || !hasLetter || !hasDigit) {
      return const Err(WeakPasswordFailure());
    }
    return Ok(Password._(raw));
  }

  /// Usada no login, onde a senha digitada só precisa ser conferida contra o
  /// hash — aplicar a regra de força aqui trancaria fora quem se cadastrou
  /// sob uma política anterior.
  static Password unchecked(String raw) => Password._(raw);

  @override
  String toString() => '******';
}
