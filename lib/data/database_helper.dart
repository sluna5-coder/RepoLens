import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/exceptions.dart';

/// Abre y crea la base de datos SQLite de la app (patrón singleton:
/// una sola conexión compartida por todos los repositorios).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'repolens.db';

  /// Versión del esquema. Al subirla se ejecuta [_onUpgrade].
  /// v2: tabla `sessions` (token de sesión aleatorio en lugar del id).
  static const int dbVersion = 2;

  Database? _db;

  /// Devuelve la conexión, abriéndola la primera vez.
  Future<Database> get database async {
    if (_db != null) return _db!;
    try {
      final path = p.join(await getDatabasesPath(), _dbName);
      _db = await openDatabase(
        path,
        version: dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return _db!;
    } catch (_) {
      throw const DatabaseAppException();
    }
  }

  /// Crea las cuatro tablas la primera vez que se instala la app.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        full_name TEXT NOT NULL,
        json_snapshot TEXT NOT NULL,
        health_score INTEGER NOT NULL,
        analyzed_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        full_name TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, full_name)
      )''');
    await db.execute('''
      CREATE TABLE cache (
        full_name TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        fetched_at TEXT NOT NULL
      )''');
    await _createSessions(db);
  }

  /// Sesiones abiertas: hash SHA-256 del token guardado en el dispositivo.
  static Future<void> _createSessions(Database db) => db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        token_hash TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TEXT NOT NULL
      )''');

  /// Migraciones entre versiones del esquema, con `if (oldVersion < N) { ... }`.
  /// La caché es desechable, así que siempre se limpia al migrar.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createSessions(db);
    await db.delete('cache');
  }
}

/// Ejecuta una operación de base de datos y convierte cualquier falla de
/// sqflite en [DatabaseAppException] para mostrar un mensaje amable.
Future<T> dbGuard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (_) {
    throw const DatabaseAppException();
  }
}
