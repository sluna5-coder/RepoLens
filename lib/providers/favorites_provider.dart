import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../data/favorite_repository.dart';
import '../models/favorite.dart';

/// Estado de los favoritos del usuario (CRUD completo).
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._repository);

  final FavoriteRepository _repository;

  List<Favorite> items = [];
  bool loading = false;
  AppException? error;

  /// Busca un favorito por nombre de repo (sin distinguir mayúsculas).
  Favorite? find(String fullName) {
    for (final f in items) {
      if (f.fullName.toLowerCase() == fullName.toLowerCase()) return f;
    }
    return null;
  }

  /// READ: consulta los favoritos en SQLite.
  Future<void> load(int userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repository.listByUser(userId);
    } on AppException catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }

  /// CREATE: agrega un favorito con nota opcional.
  Future<bool> add(int userId, String fullName, {String note = ''}) async {
    if (find(fullName) != null) return true;
    try {
      final now = DateTime.now();
      final favorite = Favorite(
        userId: userId,
        fullName: fullName,
        note: note,
        createdAt: now,
        updatedAt: now,
      );
      final id = await _repository.insert(favorite);
      items = [favorite.copyWith(id: id), ...items];
      notifyListeners();
      return true;
    } on AppException {
      return false;
    }
  }

  /// UPDATE: edita la nota.
  Future<bool> updateNote(Favorite favorite, String note) async {
    try {
      final now = DateTime.now();
      await _repository.updateNote(favorite.id!, note, now);
      items = [
        for (final f in items)
          if (f.id == favorite.id) f.copyWith(note: note, updatedAt: now) else f,
      ];
      notifyListeners();
      return true;
    } on AppException {
      return false;
    }
  }

  /// DELETE: elimina un favorito.
  Future<bool> remove(int id) async {
    try {
      await _repository.delete(id);
      items = items.where((f) => f.id != id).toList();
      notifyListeners();
      return true;
    } on AppException {
      return false;
    }
  }
}
