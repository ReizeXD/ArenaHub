/// Um horário de uma hora na agenda de uma quadra.
///
/// Não é persistido: é calculado a partir do horário de funcionamento da
/// quadra menos as reservas já existentes.
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.isAvailable,
    this.duration = const Duration(hours: 1),
  });

  final DateTime start;
  final Duration duration;
  final bool isAvailable;

  DateTime get end => start.add(duration);

  /// `19:00` — rótulo do início, com dois dígitos.
  String get label => '${start.hour.toString().padLeft(2, '0')}:00';
}
