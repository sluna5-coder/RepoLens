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

  /// Reemplaza el hash de la contraseña (migración de SHA-256 a PBKDF2).
  Future<void> updatePasswordHash(int id, String hash) => dbGuard(() async {
        final db = await _helper.database;
        await db.update('users', {'password_hash': hash}, where: 'id = ?', whereArgs: [id]);
      });

  /// Registra una sesión. Solo se guarda el hash del token, nunca el token.
  Future<void> createSession(int userId, String tokenHash) => dbGuard(() async {
        final db = await _helper.database;
        await db.insert('sessions', {
          'token_hash': tokenHash,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

  /// Usuario dueño de la sesión con ese hash, o `null` si no existe.
  Future<User?> findBySessionHash(String tokenHash) => dbGuard(() async {
        final db = await _helper.database;
        final rows = await db.rawQuery(
          'SELECT u.* FROM users u JOIN sessions s ON s.user_id = u.id '
          'WHERE s.token_hash = ? LIMIT 1',
          [tokenHash],
        );
        return rows.isEmpty ? null : User.fromJson(rows.first);
      });

  Future<void> deleteSession(String tokenHash) => dbGuard(() async {
        final db = await _helper.database;
        await db.delete('sessions', where: 'token_hash = ?', whereArgs: [tokenHash]);
      });
}
