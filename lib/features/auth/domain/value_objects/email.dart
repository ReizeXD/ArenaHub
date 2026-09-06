import '../../../../core/failure.dart';
import '../../../../core/result.dart';

/// E-mail válido por construção.
///
/// A regra de validação vive num único lugar; telas, casos de uso e
/// adaptadores apenas a consomem (SRP). Não existe `Email` inválido em
/// circulação — o construtor é privado e a única porta de entrada valida.
class Email {
  const Email._(this.value);

  final String value;

  static final RegExp _pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static Result<Email> create(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (!_pattern.hasMatch(normalized)) {
      return const Err(InvalidEmailFailure());
    }
    return Ok(Email._(normalized));
  }

  @override
  String toString() => value;
}
