import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import 'database_helper.dart';

/// Acceso a la tabla `cache`: guarda el JSON del último informe de cada repo
/// durante 30 minutos para no gastar peticiones de la API.
class CacheRepository {
  CacheRepository([DatabaseHelper? helper]) : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  /// Devuelve el JSON guardado si sigue vigente; `null` si no hay o ya venció.
  Future<String?> get(String fullName) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.query(
          'cache',
          where: 'full_name = ?',
          whereArgs: [fullName.toLowerCase()],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        final fetchedAt = DateTime.parse(rows.first['fetched_at'] as String);
        if (DateTime.now().difference(fetchedAt) > AppConstants.cacheTtl) return null;
        return rows.first['json'] as String;
      });

  /// Guarda o reemplaza el JSON de un repo.
  Future<void> put(String fullName, String json) => dbGuard(() async {
        final db = await _helper.database;
        await db.insert(
          'cache',
          {
            'full_name': fullName.toLowerCase(),
            'json': json,
            'fetched_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

  /// Borra toda la caché.
  Future<void> clear() => dbGuard(() async {
        final db = await _helper.database;
        await db.delete('cache');
      });
}
