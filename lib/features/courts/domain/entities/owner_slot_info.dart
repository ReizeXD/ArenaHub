import 'booking.dart';

/// Um horário de uma hora na agenda vista pelo dono da quadra.
class OwnerSlotInfo {
  const OwnerSlotInfo({
    required this.start,
    required this.isPast,
    this.booking,
    this.duration = const Duration(hours: 1),
  });

  final DateTime start;
  final Duration duration;
  final bool isPast;

  /// Reserva ativa neste horário, ou `null` quando o horário está livre.
  final Booking? booking;

  DateTime get end => start.add(duration);

  bool get isBooked => booking != null;

  /// `19:00` — rótulo do início, com dois dígitos.
  String get label => '${start.hour.toString().padLeft(2, '0')}:00';
}
