import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/services/session_storage.dart';
import '../mappers/session_json_mapper.dart';

/// [SessionStorage] sobre `SharedPreferences`.
class PrefsSessionStorage implements SessionStorage {
  const PrefsSessionStorage(
    this._preferences, [
    this._mapper = const SessionJsonMapper(),
  ]);

  final SharedPreferences _preferences;
  final SessionJsonMapper _mapper;

  static const String _key = 'arenahub.session';

  @override
  Future<AuthSession?> read() async {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;

    final session = _mapper.decode(raw);
    if (session == null) {
      await _preferences.remove(_key);
    }
    return session;
  }

  @override
  Future<void> save(AuthSession session) async {
    await _preferences.setString(_key, _mapper.encode(session));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
