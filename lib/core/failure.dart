/// Falhas de negócio conhecidas do ArenaHub.
///
/// Modelar as falhas como um tipo selado (em vez de lançar exceções soltas)
/// garante que qualquer implementação de um port — local, remota ou fake de
/// teste — devolva o mesmo vocabulário de erro. É o que sustenta o Princípio
/// de Substituição de Liskov: trocar o adaptador não muda como o chamador
/// trata os erros.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure() : super('Informe um e-mail válido.');
}

final class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure()
      : super('A senha precisa ter ao menos 8 caracteres, com letra e número.');
}

final class InvalidNameFailure extends Failure {
  const InvalidNameFailure() : super('Informe o nome completo.');
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('E-mail ou senha incorretos.');
}

final class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure() : super('Este e-mail já está cadastrado.');
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Falha de comunicação. Verifique sua conexão.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Falha ao acessar os dados locais.']);
}
