import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/sport.dart';
import '../../domain/usecases/list_courts.dart';
import '../states/courts_state.dart';

/// Liga a tela de listagem ao caso de uso.
class CourtsController extends ChangeNotifier {
  CourtsController(this._listCourts);

  final ListCourts _listCourts;

  CourtsState _state = const CourtsLoading();
  CourtsState get state => _state;

  /// Modalidade selecionada no filtro. `null` é "Todos".
  Sport? _sport;
  Sport? get sport => _sport;

  /// As quadras que a tela mostra, já filtradas.
  ///
  /// Filtro em memória: a lista inteira já veio do repositório, então trocar
  /// de modalidade não gera consulta nova.
  List<Court> get visibleCourts {
    final currentState = _state;
    if (currentState is! CourtsLoaded) {
      return const <Court>[];
    }
    if (_sport == null) {
      return currentState.courts;
    }
    return currentState.courts
        .where((court) => court.sport == _sport)
        .toList();
  }

  /// As modalidades que existem no catálogo carregado.
  List<Sport> get availableSports {
    final currentState = _state;
    if (currentState is! CourtsLoaded) {
      return const <Sport>[];
    }
    final result = <Sport>[];
    for (final sport in Sport.values) {
      if (currentState.courts.any((court) => court.sport == sport)) {
        result.add(sport);
      }
    }
    return result;
  }

  void filterBy(Sport? sport) {
    if (_sport == sport) return;
    _sport = sport;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(const CourtsLoading());
    final result = await _listCourts();
    if (result is Ok<List<Court>>) {
      _emit(CourtsLoaded(result.value));
    } else if (result is Err<List<Court>>) {
      _emit(CourtsFailed(result.failure));
    }
  }

  void _emit(CourtsState next) {
    _state = next;
    notifyListeners();
  }
}
