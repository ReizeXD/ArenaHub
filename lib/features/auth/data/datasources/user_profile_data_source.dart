import '../../domain/entities/role.dart';

/// Nome e papel de um usuário — o que o Firebase Authentication **não**
/// guarda.
///
/// O Auth cuida só de credencial (e-mail e senha). Cargo de usuário exigiria
/// *custom claims*, que precisam do Admin SDK rodando num servidor; guardar
/// o perfil num documento à parte resolve sem servidor nenhum.
class UserProfile {
  const UserProfile({required this.fullName, required this.role});

  final String fullName;
  final Role role;
}

/// Port de leitura e escrita do perfil.
///
/// Existe como abstração para que o repositório do Firebase não fique preso
/// ao Firestore — trocar por Realtime Database, ou por um fake no teste, é
/// outra implementação.
abstract interface class UserProfileDataSource {
  Future<UserProfile?> find(String uid);

  Future<void> save(String uid, UserProfile profile);
}
