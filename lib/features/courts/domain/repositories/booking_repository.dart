import '../../../../core/result.dart';
import '../entities/booking.dart';

/// Port de leitura e escrita das reservas.
///
/// Separado de `CourtRepository` porque as duas coisas mudam por motivos
/// diferentes: catálogo de quadras e agenda de reservas (SRP).
abstract interface class BookingRepository {
  /// Reservas de uma quadra num dia — o que define quais horários estão
  /// ocupados.
  Future<Result<List<Booking>>> forCourtOn({
    required String courtId,
    required DateTime day,
  });

  /// Reservas de um usuário, da mais próxima para a mais distante.
  Future<Result<List<Booking>>> ofUser(String userId);

  Future<Result<Booking>> create(Booking booking);
}
