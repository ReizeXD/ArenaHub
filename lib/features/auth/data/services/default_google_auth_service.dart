import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import 'social_auth_service.dart';

/// Implementação padrão que utiliza o plugin `google_sign_in`.
class DefaultGoogleAuthService implements GoogleAuthService {
  const DefaultGoogleAuthService();

  @override
  Future<SocialAuthPayload?> signIn() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      final account = await googleSignIn.authenticate();
      final auth = account.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      return SocialAuthPayload(
        credential: credential,
        fullName: account.displayName,
        email: account.email,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }
}
