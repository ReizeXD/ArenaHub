import '../../../../core/failure.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/owner_slot_info.dart';

/// Estados da agenda e grade de horários da quadra vista pelo dono.
sealed class OwnerAgendaState {
  const OwnerAgendaState();
}

/// Estado inicial ou durante carregamento da grade de horários.
final class OwnerAgendaLoading extends OwnerAgendaState {
  const OwnerAgendaLoading();
}

/// Grade de horários carregada com sucesso com métricas diárias calculadas.
final class OwnerAgendaLoaded extends OwnerAgendaState {
  const OwnerAgendaLoaded({
    required this.court,
    required this.selectedDay,
    required this.availableDays,
    required this.slots,
  });

  final Court court;
  final DateTime selectedDay;
  final List<DateTime> availableDays;
  final List<OwnerSlotInfo> slots;

  /// Quantidade de horários reservados no dia.
  int get bookedCount => slots.where((s) => s.isBooked).length;

  /// Quantidade total de horários de funcionamento no dia.
  int get totalSlots => slots.length;

  /// Quantidade de horários livres no dia.
  int get availableCount => slots.where((s) => !s.isBooked).length;

  /// Faturamento previsto ou arrecadado com as reservas do dia em centavos.
  int get revenueInCents => bookedCount * court.pricePerHourInCents;

  /// Faturamento formatado no padrão brasileiro (ex.: `R$ 240,00`).
  String get formattedRevenue {
    final reais = revenueInCents ~/ 100;
    final cents = (revenueInCents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$cents';
  }
}

/// Falha ao carregar a agenda (ex.: erro de permissão ou rede).
final class OwnerAgendaFailed extends OwnerAgendaState {
  const OwnerAgendaFailed(this.failure);

  final Failure failure;
}
