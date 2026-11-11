import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../core/validators.dart';
import '../data/cache_repository.dart';
import '../data/history_repository.dart';
import '../models/analysis_result.dart';
import '../models/history_entry.dart';
import '../services/analyzer.dart';
import '../services/connectivity_service.dart';
import '../services/github_service.dart';

enum AnalysisStatus { idle, loading, success, error }

/// Orquesta un análisis: valida la URL, revisa la caché, verifica la red,
/// consulta la API, calcula el informe y lo guarda en caché e historial.
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider({
    required GithubService github,
    required CacheRepository cache,
    required HistoryRepository history,
    required ConnectivityService connectivity,
  })  : _github = github,
        _cache = cache,
        _history = history,
        _connectivity = connectivity;

  final GithubService _github;
  final CacheRepository _cache;
  final HistoryRepository _history;
  final ConnectivityService _connectivity;

  AnalysisStatus status = AnalysisStatus.idle;
  AnalysisResult? result;

  /// Error tipado del último intento; la UI muestra `error.message`.
  AppException? error;

  /// Aviso no fatal (ej. no se pudo guardar en el historial).
  String? warning;

  static final RegExp _plainName = RegExp(r'^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$');

  /// Obtiene el informe de un repo sin tocar el estado de la pantalla
  /// (lo usa también la comparación). Lanza [AppException] si algo falla.
  /// [force] ignora la caché y vuelve a consultar la API.
  Future<AnalysisResult> load(String input, {bool force = false}) async {
    final text = input.trim();
    final fullName = _plainName.hasMatch(text) ? text : Validators.parseRepoUrl(text);
    if (fullName == null) throw const InvalidUrlException();

    // 1) Caché de 30 minutos. Si la BD falla se sigue con la red.
    if (!force) {
      try {
        final cached = await _cache.get(fullName);
        if (cached != null) {
          return AnalysisResult.fromJson(jsonDecode(cached) as Map<String, dynamic>)
              .copyWith(fromCache: true);
        }
      } catch (_) {/* caché ilegible: se ignora */}
    }

    // 2) Sin red no tiene caso intentar la petición.
    if (!await _connectivity.hasConnection()) throw const NoConnectionException();

    // 3) API + análisis propio.
    final data = await _github.fetchAll(fullName);
    final analysis = Analyzer.build(data);

    // 4) Guardar en caché (si falla no se pierde el informe).
    try {
      await _cache.put(fullName, jsonEncode(analysis.toJson()));
    } catch (_) {/* se ignora */}
    return analysis;
  }

  /// Analiza un repo para la pantalla principal y lo guarda en el historial
  /// del usuario. Devuelve el informe o `null` si hubo error.
  Future<AnalysisResult?> analyze(String input, {required int userId, bool force = false}) async {
    status = AnalysisStatus.loading;
    error = null;
    warning = null;
    notifyListeners();
    try {
      final analysis = await load(input, force: force);
      result = analysis;
      status = AnalysisStatus.success;
      try {
        await _history.insert(HistoryEntry(
          userId: userId,
          fullName: analysis.repo.fullName,
          jsonSnapshot: jsonEncode(analysis.toJson()),
          healthScore: analysis.healthScore,
          analyzedAt: DateTime.now(),
        ));
      } on AppException catch (e) {
        warning = 'El informe no se guardó en el historial. ${e.message}';
      }
      return analysis;
    } on AppException catch (e) {
      error = e;
      status = AnalysisStatus.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  /// Regresa la pantalla al estado inicial.
  void reset() {
    status = AnalysisStatus.idle;
    error = null;
    notifyListeners();
  }
}
