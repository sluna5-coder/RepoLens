import '../models/user.dart';
import 'database_helper.dart';

/// Acceso a la tabla `users`.
class UserRepository {
  UserRepository([DatabaseHelper? helper]) : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  /// Inserta un usuario y devuelve su id.
  Future<int> insert(User user) => dbGuard(() async {
        final db = await _helper.database;
        return db.insert('users', user.toJson());
      });

  /// Busca por email (ya normalizado a minúsculas).
  Future<User?> findByEmail(String email) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
        return rows.isEmpty ? null : User.fromJson(rows.first);
      });

  Future<User?> findById(int id) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
        return rows.isEmpty ? null : User.fromJson(rows.first);
      });
}
