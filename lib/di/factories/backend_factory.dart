import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/courts/domain/repositories/booking_repository.dart';
import '../../features/courts/domain/repositories/court_repository.dart';
import '../../features/courts/domain/services/court_image_storage.dart';

/// Fábrica Abstrata (Abstract Factory Pattern):
/// Define o contrato para criar uma família completa e compatível de
/// repositórios e serviços de infraestrutura (Local ou Firebase).
abstract class BackendFactory {
  Future<void> initialize();

  Future<AuthRepository> createAuthRepository();

  CourtRepository createCourtRepository();

  BookingRepository createBookingRepository();

  CourtImageStorage createCourtImageStorage();
}
