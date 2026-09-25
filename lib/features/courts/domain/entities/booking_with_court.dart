import 'booking.dart';
import 'court.dart';

/// Uma reserva junto da quadra a que ela pertence.
///
/// Existe porque o documento da reserva guarda só o `courtId` — banco de
/// documentos não tem JOIN. A junção acontece no caso de uso, que lê as duas
/// coleções e cruza em memória. Para a tela, o resultado é o mesmo que uma
/// consulta com JOIN entregaria.
class BookingWithCourt {
  const BookingWithCourt({
    required this.booking,
    required this.court,
    required this.isPast,
  });

  final Booking booking;
  final Court court;

  /// Já aconteceu — a tela mostra em cinza, na seção de anteriores.
  final bool isPast;

  /// `28/09` — dia e mês do jogo.
  String get formattedDate {
    final day = booking.start.day.toString().padLeft(2, '0');
    final month = booking.start.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  /// `19:00 às 20:00`
  String get formattedTime {
    String hour(DateTime moment) =>
        '${moment.hour.toString().padLeft(2, '0')}:00';
    return '${hour(booking.start)} às ${hour(booking.end)}';
  }
}
