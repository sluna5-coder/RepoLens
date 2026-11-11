import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../data/history_repository.dart';
import '../models/history_entry.dart';

/// Estado del historial de análisis del usuario.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repository);

  final HistoryRepository _repository;

  List<HistoryEntry> entries = [];
  bool loading = false;
  AppException? error;

  /// Consulta el historial en SQLite.
  Future<void> load(int userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      entries = await _repository.listByUser(userId);
    } on AppException catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }

  /// Elimina una entrada. Devuelve `false` si la base de datos falla.
  Future<bool> remove(int id) async {
    try {
      await _repository.delete(id);
      entries = entries.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } on AppException {
      return false;
    }
  }

  /// Vacía todo el historial del usuario.
  Future<bool> clear(int userId) async {
    try {
      await _repository.clear(userId);
      entries = [];
      notifyListeners();
      return true;
    } on AppException {
      return false;
    }
  }
}
