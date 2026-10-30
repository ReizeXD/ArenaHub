import 'package:flutter/foundation.dart';

/// Define o contexto de navegação ativo no aplicativo.
enum AppMode {
  athlete,
  owner;

  bool get isAthlete => this == AppMode.athlete;
  bool get isOwner => this == AppMode.owner;
}

/// Gerencia o estado de alternância entre o Modo Atleta e o Modo Proprietário.
class AppModeController extends ChangeNotifier {
  AppModeController({AppMode initialMode = AppMode.athlete})
      : _mode = initialMode;

  AppMode _mode;
  AppMode get mode => _mode;

  void setMode(AppMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }

  void toggle() {
    _mode = _mode == AppMode.athlete ? AppMode.owner : AppMode.athlete;
    notifyListeners();
  }
}
