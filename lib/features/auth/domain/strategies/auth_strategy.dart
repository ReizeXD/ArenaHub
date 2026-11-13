import '../../../../core/result.dart';
import '../entities/auth_session.dart';

/// Um mecanismo de autenticação intercambiável (Strategy).
abstract interface class AuthStrategy {
  Future<Result<AuthSession>> authenticate();
}
