import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/owner_slot_info.dart';
import '../../domain/usecases/get_owner_court_agenda.dart';
import '../states/owner_agenda_state.dart';

/// Controlador da agenda e métricas da quadra na visão do proprietário.
///
/// Gerencia a busca de slots diários através de [GetOwnerCourtAgenda],
/// a navegação entre datas e o cálculo dinâmico de métricas (reservas e faturamento).
class OwnerAgendaController extends ChangeNotifier {
  OwnerAgendaController(
    this._getOwnerCourtAgenda, {
    DateTime Function()? now,
    this.daysAhead = defaultDaysAhead,
  })  : _now = now ?? DateTime.now {
    _selectedDay = _stripTime(_now());
  }

  final GetOwnerCourtAgenda _getOwnerCourtAgenda;
  final DateTime Function() _now;

  /// Quantidade de dias oferecidos na grade a partir de hoje.
  static const int defaultDaysAhead = 14;
  final int daysAhead;

  Court? _court;
  Court? get court => _court;

  String? _userId;
  String? get userId => _userId;

  late DateTime _selectedDay;
  DateTime get selectedDay => _selectedDay;

  OwnerAgendaState _state = const OwnerAgendaLoading();
  OwnerAgendaState get state => _state;

  /// Dias disponíveis para seleção na agenda, a partir de hoje.
  List<DateTime> get availableDays {
    final today = _stripTime(_now());
    return List<DateTime>.generate(
      daysAhead,
      (index) => today.add(Duration(days: index)),
    );
  }

  /// Lista de slots do estado atual (vazia se carregando ou com falha).
  List<OwnerSlotInfo> get slots {
    final currentState = _state;
    if (currentState is OwnerAgendaLoaded) return currentState.slots;
    return const [];
  }

  /// Total de slots agendados no dia atual.
  int get bookedCount {
    final currentState = _state;
    if (currentState is OwnerAgendaLoaded) return currentState.bookedCount;
    return 0;
  }

  /// Total de slots disponíveis na grade do dia.
  int get totalSlots {
    final currentState = _state;
    if (currentState is OwnerAgendaLoaded) return currentState.totalSlots;
    return 0;
  }

  /// Faturamento previsto no dia selecionado em centavos.
  int get revenueInCents {
    final currentState = _state;
    if (currentState is OwnerAgendaLoaded) return currentState.revenueInCents;
    return 0;
  }

  /// Faturamento previsto formatado em R$.
  String get formattedRevenue {
    final currentState = _state;
    if (currentState is OwnerAgendaLoaded) return currentState.formattedRevenue;
    return 'R\$ 0,00';
  }

  /// Inicializa e carrega a agenda para uma quadra em uma data específica.
  Future<void> load({
    required Court court,
    DateTime? day,
    String? userId,
  }) async {
    _court = court;
    _userId = userId;
    _selectedDay = _stripTime(day ?? _now());
    await _fetchSlots();
  }

  /// Alterna o dia ativo da agenda e atualiza a grade.
  Future<void> selectDay(DateTime day) async {
    final normalized = _stripTime(day);
    if (normalized == _selectedDay && _state is OwnerAgendaLoaded) return;

    _selectedDay = normalized;
    await _fetchSlots();
  }

  /// Recarrega os dados do dia atualmente selecionado.
  Future<void> reload() async {
    await _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final currentCourt = _court;
    if (currentCourt == null) return;

    _state = const OwnerAgendaLoading();
    notifyListeners();

    final result = await _getOwnerCourtAgenda(
      court: currentCourt,
      day: _selectedDay,
      userId: _userId,
    );

    if (result is Ok<List<OwnerSlotInfo>>) {
      _state = OwnerAgendaLoaded(
        court: currentCourt,
        selectedDay: _selectedDay,
        availableDays: availableDays,
        slots: result.value,
      );
    } else if (result is Err<List<OwnerSlotInfo>>) {
      _state = OwnerAgendaFailed(result.failure);
    }

    notifyListeners();
  }

  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
