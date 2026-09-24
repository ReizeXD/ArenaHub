import '../../../../core/failure.dart';
import '../../domain/entities/time_slot.dart';

/// Estados da agenda de uma quadra num dia.
sealed class AgendaState {
  const AgendaState();
}

final class AgendaLoading extends AgendaState {
  const AgendaLoading();
}

final class AgendaLoaded extends AgendaState {
  const AgendaLoaded(this.slots);

  final List<TimeSlot> slots;

  bool get hasAnyAvailable => slots.any((slot) => slot.isAvailable);
}

final class AgendaFailed extends AgendaState {
  const AgendaFailed(this.failure);

  final Failure failure;
}
