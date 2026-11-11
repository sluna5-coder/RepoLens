import '../models/favorite.dart';
import 'database_helper.dart';

/// Acceso a la tabla `favorites` con CRUD completo.
class FavoriteRepository {
  FavoriteRepository([DatabaseHelper? helper]) : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  /// CREATE: agrega un favorito y devuelve su id.
  Future<int> insert(Favorite favorite) => dbGuard(() async {
        final db = await _helper.database;
        return db.insert('favorites', favorite.toJson());
      });

  /// READ: favoritos del usuario, del más reciente al más antiguo.
  Future<List<Favorite>> listByUser(int userId) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.query(
          'favorites',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
        );
        return rows.map(Favorite.fromJson).toList();
      });

  /// UPDATE: cambia la nota y la fecha de actualización.
  Future<void> updateNote(int id, String note, DateTime updatedAt) => dbGuard(() async {
        final db = await _helper.database;
        await db.update(
          'favorites',
          {'note': note, 'updated_at': updatedAt.toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  /// DELETE: elimina un favorito.
  Future<void> delete(int id) => dbGuard(() async {
        final db = await _helper.database;
        await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
      });
}
