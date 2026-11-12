import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/commit_info.dart';
import '../models/contributor.dart';
import '../models/language_stat.dart';
import '../models/repo_file.dart';
import '../models/repo_info.dart';

/// Datos crudos de un repositorio ya convertidos a modelos.
/// El Analyzer los recibe para armar el informe final.
class RepoData {
  const RepoData({
    required this.repo,
    required this.languages,
    required this.commits,
    required this.contributors,
    required this.files,
    required this.readme,
    this.tree = const [],
    this.treeTruncated = false,
  });

  final RepoInfo repo;
  final List<LanguageStat> languages;
  final List<CommitInfo> commits;
  final List<Contributor> contributors;
  final List<RepoFile> files;
  final String? readme;

  /// Todos los archivos y carpetas del repositorio (vacío si no se pudo leer).
  final List<RepoFile> tree;

  /// `true` si GitHub recortó el árbol por ser muy grande.
  final bool treeTruncated;
}

/// Único punto de la app que hace peticiones HTTP a la API de GitHub.
///
/// Recibe un [http.Client] inyectable: en producción es un cliente real y en
/// las pruebas un `MockClient` que simula las respuestas.
class GithubService {
  GithubService({
    http.Client? client,
    this.tokenProvider,
    this.timeout = AppConstants.timeout,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Devuelve el token personal guardado (o `null`). Se consulta en cada
  /// petición para que un token recién guardado aplique de inmediato.
  final Future<String?> Function()? tokenProvider;
  final Duration timeout;

  /// GET /repos/{owner}/{repo}: datos generales.
  Future<RepoInfo> getRepo(String fullName) async {
    final json = await _get('/repos/$fullName');
    return _parse(() => RepoInfo.fromJson(json as Map<String, dynamic>));
  }

  /// GET /repos/{owner}/{repo}/languages: bytes por lenguaje -> porcentajes.
  Future<List<LanguageStat>> getLanguages(String fullName) async {
    final json = await _get('/repos/$fullName/languages');
    return _parse(() => LanguageStat.listFromApi(json as Map<String, dynamic>));
  }

  /// GET /repos/{owner}/{repo}/commits?per_page=10: commits recientes.
  /// Un 409 significa repositorio vacío y se lanza [EmptyRepoException].
  Future<List<CommitInfo>> getCommits(String fullName) async {
    final json = await _get('/repos/$fullName/commits?per_page=10');
    return _parseList(json, CommitInfo.fromJson);
  }

  /// GET /repos/{owner}/{repo}/contributors?per_page=10.
  Future<List<Contributor>> getContributors(String fullName) async {
    final json = await _get('/repos/$fullName/contributors?per_page=10');
    if (json == null) return []; // 204: sin contribuidores
    return _parseList(json, Contributor.fromJson);
  }

  /// GET /repos/{owner}/{repo}/contents: archivos de la raíz.
  Future<List<RepoFile>> getContents(String fullName) async {
    final json = await _get('/repos/$fullName/contents');
    return _parseList(json, RepoFile.fromJson);
  }

  /// GET /repos/{owner}/{repo}/readme: decodifica el base64 a texto Markdown.
  /// Devuelve `null` si el repo no tiene README (404).
  Future<String?> getReadme(String fullName) async {
    final dynamic json;
    try {
      json = await _get('/repos/$fullName/readme');
    } on NotFoundException {
      return null;
    }
    return _parse<String>(() {
      final content = (json as Map<String, dynamic>)['content'] as String;
      // GitHub parte el base64 en líneas: se quitan los saltos antes de decodificar.
      return utf8.decode(base64.decode(content.replaceAll(RegExp(r'\s'), '')),
          allowMalformed: true);
    });
  }

  /// GET /repos/{owner}/{repo}/git/trees/{rama}?recursive=1: todo el árbol del
  /// repositorio en una sola petición. GitHub lo recorta en repos enormes y lo
  /// indica con `truncated`.
  Future<({List<RepoFile> files, bool truncated})> getTree(
      String fullName, String branch) async {
    final json = await _get(
        '/repos/$fullName/git/trees/${Uri.encodeComponent(branch)}?recursive=1');
    return _parse(() {
      final map = json as Map<String, dynamic>;
      final files = (map['tree'] as List).map((e) {
        final item = e as Map<String, dynamic>;
        final path = item['path'] as String;
        return RepoFile(
          name: path.split('/').last,
          path: path,
          type: item['type'] == 'tree' ? 'dir' : 'file',
          size: (item['size'] as int?) ?? 0,
        );
      }).toList();
      return (files: files, truncated: (map['truncated'] as bool?) ?? false);
    });
  }

  /// Descarga todo lo necesario para el informe. Primero el repo (si no existe
  /// se corta ahí) y luego el resto en paralelo para ahorrar tiempo.
  Future<RepoData> fetchAll(String fullName) async {
    final repo = await getRepo(fullName);
    final results = await Future.wait<Object?>([
      getLanguages(fullName),
      getCommits(fullName),
      // La lista de contribuidores puede fallar en repos enormes (403 sin ser
      // límite de peticiones); en ese caso se muestra vacía.
      getContributors(fullName).onError<ApiException>((_, _) => <Contributor>[]),
      getContents(fullName),
      getReadme(fullName),
      _treeOrEmpty(fullName, repo.defaultBranch),
    ]);
    final tree = results[5] as ({List<RepoFile> files, bool truncated});
    return RepoData(
      repo: repo,
      languages: results[0] as List<LanguageStat>,
      commits: results[1] as List<CommitInfo>,
      contributors: results[2] as List<Contributor>,
      files: results[3] as List<RepoFile>,
      readme: results[4] as String?,
      tree: tree.files,
      treeTruncated: tree.truncated,
    );
  }

  /// El árbol es un extra: si falla (salvo por red o límite de peticiones),
  /// el informe sale igual con los archivos de la raíz.
  Future<({List<RepoFile> files, bool truncated})> _treeOrEmpty(
      String fullName, String branch) async {
    try {
      return await getTree(fullName, branch);
    } on RateLimitException {
      rethrow;
    } on NoConnectionException {
      rethrow;
    } on RequestTimeoutException {
      rethrow;
    } on AppException {
      return (files: <RepoFile>[], truncated: false);
    }
  }

  /// Hace el GET, aplica el timeout y traduce cada falla a una excepción tipada.
  Future<dynamic> _get(String path) async {
    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'RepoLens-App',
    };
    final token = await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response res;
    try {
      res = await _client
          .get(Uri.parse('${AppConstants.apiBase}$path'), headers: headers)
          .timeout(timeout);
    } on SocketException {
      throw const NoConnectionException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NoConnectionException();
    }

    switch (res.statusCode) {
      case 200:
        try {
          return jsonDecode(utf8.decode(res.bodyBytes));
        } on FormatException {
          throw const UnexpectedJsonException();
        }
      case 204:
        return null;
      case 404:
        throw const NotFoundException();
      case 409:
        throw const EmptyRepoException();
      case 429:
        throw RateLimitException(resetAt: _resetAt(res));
      case 403:
        // 403 es límite de peticiones solo si ya no quedan disponibles.
        if (res.headers['x-ratelimit-remaining'] == '0' ||
            res.headers.containsKey('retry-after')) {
          throw RateLimitException(resetAt: _resetAt(res));
        }
        throw const ApiException(403);
      default:
        throw ApiException(res.statusCode);
    }
  }

  /// Lee X-RateLimit-Reset (segundos desde 1970) y lo convierte a fecha.
  DateTime? _resetAt(http.Response res) {
    final seconds = int.tryParse(res.headers['x-ratelimit-reset'] ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  /// Ejecuta un parseo y convierte errores de tipo en [UnexpectedJsonException].
  T _parse<T>(T Function() build) {
    try {
      return build();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnexpectedJsonException();
    }
  }

  List<T> _parseList<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) =>
      _parse(() => (json as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList());
}
