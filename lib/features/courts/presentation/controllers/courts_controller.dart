import 'package:flutter/foundation.dart';

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
  List<Court> get visibleCourts => switch (_state) {
        CourtsLoaded(:final courts) => _sport == null
            ? courts
            : courts.where((court) => court.sport == _sport).toList(),
        _ => const <Court>[],
      };

  /// As modalidades que existem no catálogo carregado.
  List<Sport> get availableSports => switch (_state) {
        CourtsLoaded(:final courts) => [
            for (final sport in Sport.values)
              if (courts.any((court) => court.sport == sport)) sport,
          ],
        _ => const <Sport>[],
      };

  void filterBy(Sport? sport) {
    if (_sport == sport) return;
    _sport = sport;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(const CourtsLoading());
    _emit(
      (await _listCourts()).fold(
        onSuccess: (List<Court> courts) => CourtsLoaded(courts),
        onFailure: CourtsFailed.new,
      ),
    );
  }

  void _emit(CourtsState next) {
    _state = next;
    notifyListeners();
  }
}
