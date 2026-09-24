import 'package:flutter/foundation.dart';

import '../../domain/entities/court.dart';
import '../../domain/usecases/list_courts.dart';
import '../states/courts_state.dart';

/// Liga a tela de listagem ao caso de uso.
///
/// Como o `AuthController`, depende apenas de caso de uso — não sabe se as
/// quadras vêm de memória, do Firestore ou de uma API.
class CourtsController extends ChangeNotifier {
  CourtsController(this._listCourts);

  final ListCourts _listCourts;

  CourtsState _state = const CourtsLoading();
  CourtsState get state => _state;

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
