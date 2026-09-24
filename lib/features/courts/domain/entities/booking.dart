/// Uma reserva de uma hora numa quadra.
class Booking {
  const Booking({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.start,
    this.duration = const Duration(hours: 1),
  });

  final String id;
  final String courtId;
  final String userId;
  final DateTime start;
  final Duration duration;

  DateTime get end => start.add(duration);

  /// Duas reservas ocupam o mesmo horário quando começam na mesma hora do
  /// mesmo dia — a granularidade do sistema é de uma hora.
  bool startsAt(DateTime other) =>
      start.year == other.year &&
      start.month == other.month &&
      start.day == other.day &&
      start.hour == other.hour;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Booking && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
