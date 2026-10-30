/// Falhas de negócio conhecidas do ArenaHub.
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
  const NetworkFailure([
    super.message = 'Falha de comunicação. Verifique sua conexão.',
  ]);
}

final class CourtNotFoundFailure extends Failure {
  const CourtNotFoundFailure() : super('Quadra não encontrada.');
}

final class SlotUnavailableFailure extends Failure {
  const SlotUnavailableFailure() : super('Este horário já foi reservado.');
}

final class SlotInThePastFailure extends Failure {
  const SlotInThePastFailure()
    : super('Escolha um horário que ainda não passou.');
}

final class OutsideOperatingHoursFailure extends Failure {
  const OutsideOperatingHoursFailure()
    : super('A quadra não abre neste horário.');
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Falha ao acessar os dados locais.']);
}

final class InvalidCourtNameFailure extends Failure {
  const InvalidCourtNameFailure()
    : super('Informe um nome válido para a quadra.');
}

final class InvalidCourtAddressFailure extends Failure {
  const InvalidCourtAddressFailure() : super('Informe o endereço da quadra.');
}

final class InvalidCourtPriceFailure extends Failure {
  const InvalidCourtPriceFailure()
    : super('O valor por hora deve ser maior que zero.');
}

final class InvalidOperatingHoursFailure extends Failure {
  const InvalidOperatingHoursFailure()
    : super('O horário de fechamento deve ser posterior ao de abertura.');
}

final class UnauthorizedCourtActionFailure extends Failure {
  const UnauthorizedCourtActionFailure()
    : super('Você só pode gerenciar quadras que você mesmo cadastrou.');
}

final class ImageUploadFailure extends Failure {
  const ImageUploadFailure([
    super.message = 'Não foi possível enviar a foto da quadra.',
  ]);
}

final class OAuthCancelledFailure extends Failure {
  const OAuthCancelledFailure([
    super.message = 'Autenticação cancelada pelo usuário.',
  ]);
}

final class OAuthNetworkFailure extends Failure {
  const OAuthNetworkFailure([
    super.message = 'Falha de comunicação com o serviço de autenticação.',
  ]);
}

final class OAuthAccountCollisionFailure extends Failure {
  const OAuthAccountCollisionFailure([
    super.message =
        'Já existe uma conta cadastrada com este e-mail através de outro método.',
  ]);
}
