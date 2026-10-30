import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'social_auth_service.dart';

/// Implementação padrão que utiliza o plugin `sign_in_with_apple`.
class DefaultAppleAuthService implements AppleAuthService {
  const DefaultAppleAuthService();

  @override
  Future<SocialAuthPayload?> signIn() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final credential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final fullNameParts = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();

      final fullName = fullNameParts.isNotEmpty ? fullNameParts.join(' ') : null;

      return SocialAuthPayload(
        credential: credential,
        fullName: fullName,
        email: appleCredential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}
