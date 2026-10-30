import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Dados essenciais retornados após o fluxo de login social.
class SocialAuthPayload {
  const SocialAuthPayload({
    required this.credential,
    this.fullName,
    this.email,
  });

  /// Credencial de autenticação gerada para o Firebase.
  final fb.AuthCredential credential;

  /// Nome completo fornecido pelo provedor social, quando disponível.
  final String? fullName;

  /// E-mail do usuário no provedor social, quando disponível.
  final String? email;
}

/// Contrato para o serviço de autenticação com o Google.
abstract interface class GoogleAuthService {
  /// Executa o fluxo de autenticação com o Google.
  /// Retorna [SocialAuthPayload] em caso de sucesso, ou `null` se o usuário cancelou.
  Future<SocialAuthPayload?> signIn();
}

/// Contrato para o serviço de autenticação com a Apple.
abstract interface class AppleAuthService {
  /// Executa o fluxo de autenticação com a Apple.
  /// Retorna [SocialAuthPayload] em caso de sucesso, ou `null` se o usuário cancelou.
  Future<SocialAuthPayload?> signIn();
}
