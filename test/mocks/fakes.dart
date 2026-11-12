import 'package:repolens/data/user_repository.dart';
import 'package:repolens/models/user.dart';

/// Repositorio de usuarios en memoria: sustituye a SQLite en las pruebas.
class FakeUserRepository implements UserRepository {
  final List<User> _users = [];

  /// Sesiones abiertas: hash del token -> id del usuario.
  final Map<String, int> sessions = {};

  @override
  Future<int> insert(User user) async {
    final id = _users.length + 1;
    _users.add(user.copyWith(id: id));
    return id;
  }

  @override
  Future<User?> findByEmail(String email) async {
    for (final u in _users) {
      if (u.email == email) return u;
    }
    return null;
  }

  @override
  Future<User?> findById(int id) async {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  Future<void> updatePasswordHash(int id, String hash) async {
    final i = _users.indexWhere((u) => u.id == id);
    final u = _users[i];
    _users[i] = User(
      id: u.id,
      name: u.name,
      email: u.email,
      passwordHash: hash,
      salt: u.salt,
      createdAt: u.createdAt,
    );
  }

  @override
  Future<void> createSession(int userId, String tokenHash) async =>
      sessions[tokenHash] = userId;

  @override
  Future<User?> findBySessionHash(String tokenHash) async {
    final id = sessions[tokenHash];
    return id == null ? null : findById(id);
  }

  @override
  Future<void> deleteSession(String tokenHash) async => sessions.remove(tokenHash);
}
