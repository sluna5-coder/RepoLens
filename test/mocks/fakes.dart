import 'package:repolens/data/user_repository.dart';
import 'package:repolens/models/user.dart';

/// Repositorio de usuarios en memoria: sustituye a SQLite en las pruebas.
class FakeUserRepository implements UserRepository {
  final List<User> _users = [];

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
}
