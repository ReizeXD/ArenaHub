import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user_record.dart';
import 'user_data_source.dart';

/// [UserDataSource] sobre SQLite — usado em Android/iOS.
class SqfliteUserDataSource implements UserDataSource {
  SqfliteUserDataSource._(this._db);

  final Database _db;

  static const String _table = 'users';

  static Future<SqfliteUserDataSource> open({
    String fileName = 'arenahub.db',
  }) async {
    final path = p.join(await getDatabasesPath(), fileName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          full_name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          role TEXT NOT NULL,
          password_hash TEXT NOT NULL
        )
      '''),
    );
    return SqfliteUserDataSource._(db);
  }

  @override
  Future<UserRecord?> findByEmail(String email) async {
    final rows = await _db.query(
      _table,
      where: 'email = ?',
      whereArgs: <Object?>[email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRecord.fromRow(rows.first);
  }

  @override
  Future<bool> existsByEmail(String email) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table WHERE email = ?',
      <Object?>[email],
    );
    return (Sqflite.firstIntValue(rows) ?? 0) > 0;
  }

  @override
  Future<void> insert(UserRecord record) => _db.insert(_table, record.toRow());
}
