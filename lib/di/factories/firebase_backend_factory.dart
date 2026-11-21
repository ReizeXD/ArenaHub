import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../../features/auth/data/datasources/firestore_user_profile_data_source.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/courts/data/repositories/firestore_booking_repository.dart';
import '../../features/courts/data/repositories/firestore_court_repository.dart';
import '../../features/courts/data/repositories/seeding_court_repository.dart';
import '../../features/courts/data/seed/firestore_court_seeder.dart';
import '../../features/courts/data/services/firebase_court_image_storage.dart';
import '../../features/courts/domain/repositories/booking_repository.dart';
import '../../features/courts/domain/repositories/court_repository.dart';
import '../../features/courts/domain/services/court_image_storage.dart';
import '../../firebase_options.dart';
import 'backend_factory.dart';

/// Fábrica Concreta 2: cria a família de objetos para o modo Cloud (Firebase).
/// Usa Firebase Auth, Cloud Firestore e Firebase Storage.
class FirebaseBackendFactory implements BackendFactory {
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthRepository> createAuthRepository() async {
    return FirebaseAuthRepository(
      fb.FirebaseAuth.instance,
      FirestoreUserProfileDataSource(FirebaseFirestore.instance),
    );
  }

  @override
  CourtRepository createCourtRepository() {
    final firestore = FirebaseFirestore.instance;
    return SeedingCourtRepository(
      FirestoreCourtRepository(firestore),
      FirestoreCourtSeeder(firestore).seed,
    );
  }

  @override
  BookingRepository createBookingRepository() {
    return FirestoreBookingRepository(FirebaseFirestore.instance);
  }

  @override
  CourtImageStorage createCourtImageStorage() {
    return FirebaseCourtImageStorage();
  }
}
