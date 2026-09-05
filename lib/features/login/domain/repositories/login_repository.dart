import '../entities/user.dart';

abstract class ILoginRepository {
  Future<User> login(String email, String password);
}
