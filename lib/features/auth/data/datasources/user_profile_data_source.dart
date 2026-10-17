import '../../domain/entities/role.dart';

/// Nome e papel de um usuário — o que o Firebase Authentication **não**
/// guarda.
class UserProfile {
  const UserProfile({required this.fullName, required this.role});

  final String fullName;
  final Role role;
}

/// Port de leitura e escrita do perfil.
abstract interface class UserProfileDataSource {
  Future<UserProfile?> find(String uid);

  Future<void> save(String uid, UserProfile profile);
}
