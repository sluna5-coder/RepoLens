import '../models/history_entry.dart';
import 'database_helper.dart';

/// Acceso a la tabla `history`: crear, consultar, eliminar uno y vaciar.
class HistoryRepository {
  HistoryRepository([DatabaseHelper? helper]) : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  /// Guarda un análisis y devuelve su id.
  Future<int> insert(HistoryEntry entry) => dbGuard(() async {
        final db = await _helper.database;
        return db.insert('history', entry.toJson());
      });

  /// Historial del usuario, del más reciente al más antiguo.
  Future<List<HistoryEntry>> listByUser(int userId) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.query(
          'history',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'analyzed_at DESC',
        );
        return rows.map(HistoryEntry.fromJson).toList();
      });

  /// Elimina una entrada.
  Future<void> delete(int id) => dbGuard(() async {
        final db = await _helper.database;
        await db.delete('history', where: 'id = ?', whereArgs: [id]);
      });

  /// Vacía todo el historial del usuario.
  Future<void> clear(int userId) => dbGuard(() async {
        final db = await _helper.database;
        await db.delete('history', where: 'user_id = ?', whereArgs: [userId]);
      });
}
