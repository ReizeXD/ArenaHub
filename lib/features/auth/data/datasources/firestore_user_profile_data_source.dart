import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/role.dart';
import 'user_profile_data_source.dart';

/// [UserProfileDataSource] sobre Cloud Firestore, na coleção `users`.
///
/// Um documento por usuário, com o mesmo id que o Firebase Auth atribui.
class FirestoreUserProfileDataSource implements UserProfileDataSource {
  const FirestoreUserProfileDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  @override
  Future<UserProfile?> find(String uid) async {
    final snapshot = await _firestore.collection(_collection).doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;

    return UserProfile(
      fullName: (data['full_name'] as String?) ?? '',
      role: Role.fromWire((data['role'] as String?) ?? ''),
    );
  }

  @override
  Future<void> save(String uid, UserProfile profile) =>
      _firestore.collection(_collection).doc(uid).set(<String, Object?>{
        'full_name': profile.fullName,
        'role': profile.role.wire,
      });
}
