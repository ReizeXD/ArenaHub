import 'package:flutter/foundation.dart';

import '../../../../core/failure.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/usecases/book_court.dart';
import '../../domain/usecases/get_court_availability.dart';
import '../states/agenda_state.dart';

/// Liga a tela de detalhe da quadra aos casos de uso de agenda e reserva.
class BookingController extends ChangeNotifier {
  BookingController(
    this._getAvailability,
    this._bookCourt, {
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now {
    // Inicializado já no construtor: a tela constrói um frame antes de
    // `open()` rodar, e ler um campo `late` vazio aí quebraria a página.
    _selectedDay = _today();
  }

  final GetCourtAvailability _getAvailability;
  final BookCourt _bookCourt;
  final DateTime Function() _now;

  /// Quantos dias para a frente a tela oferece.
  static const int daysAhead = 7;

  Court? _court;
  Court? get court => _court;

  late DateTime _selectedDay;
  DateTime get selectedDay => _selectedDay;

  AgendaState _state = const AgendaLoading();
  AgendaState get state => _state;

  bool _isBooking = false;
  bool get isBooking => _isBooking;

  /// Os dias que a tela oferece, a partir de hoje.
  List<DateTime> get availableDays {
    final today = _today();
    return List<DateTime>.generate(
      daysAhead,
      (index) => today.add(Duration(days: index)),
    );
  }

  /// Abre a agenda de uma quadra no dia de hoje.
  Future<void> open(Court court) async {
    _court = court;
    _selectedDay = _today();
    await _reload();
  }

  Future<void> selectDay(DateTime day) async {
    _selectedDay = day;
    await _reload();
  }

  /// Reserva o horário. Devolve a falha quando não deu, `null` no sucesso —
  /// a tela usa isso para decidir entre mensagem de erro e confirmação.
  Future<Failure?> book({required TimeSlot slot, required String userId}) async {
    _isBooking = true;
    notifyListeners();

    final court = _court;
    if (court == null) return const StorageFailure();

    final result = await _bookCourt(
      court: court,
      userId: userId,
      start: slot.start,
    );

    _isBooking = false;

    final failure = result.fold(
      onSuccess: (Booking _) => null,
      onFailure: (Failure failure) => failure,
    );

    // Recarrega em qualquer caso: no sucesso para marcar o horário como
    // ocupado, no erro porque a agenda pode ter mudado por baixo.
    await _reload();
    return failure;
  }

  Future<void> _reload() async {
    final court = _court;
    if (court == null) return;

    _emit(const AgendaLoading());
    _emit(
      (await _getAvailability(court: court, day: _selectedDay)).fold(
        onSuccess: (List<TimeSlot> slots) => AgendaLoaded(slots),
        onFailure: AgendaFailed.new,
      ),
    );
  }

  DateTime _today() {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  void _emit(AgendaState next) {
    _state = next;
    notifyListeners();
  }
}
