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

  /// Identidade derivada do que a reserva ocupa: quadra, dia e hora.
  static String slotId({required String courtId, required DateTime start}) {
    final month = start.month.toString().padLeft(2, '0');
    final day = start.day.toString().padLeft(2, '0');
    final hour = start.hour.toString().padLeft(2, '0');
    return '${courtId}__${start.year}-$month-$day'
        '__$hour';
  }

  /// Chave de consulta da agenda: `pajucara|2026-09-28`.
  static String courtDayKey({
    required String courtId,
    required DateTime day,
  }) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '$courtId|${day.year}-$month-$dayOfMonth';
  }

  /// `2026-09-28` — o dia, sem a quadra.
  static String dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

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
