import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Respuestas JSON de ejemplo con la misma forma que la API de GitHub.
const String repoJson = '''
{
  "full_name": "octocat/demo",
  "name": "demo",
  "owner": {"login": "octocat", "avatar_url": "https://example.com/a.png"},
  "html_url": "https://github.com/octocat/demo",
  "description": "Repositorio de prueba",
  "stargazers_count": 1500,
  "forks_count": 42,
  "watchers_count": 1500,
  "subscribers_count": 30,
  "open_issues_count": 7,
  "license": {"key": "mit", "name": "MIT License"},
  "size": 2048,
  "default_branch": "main",
  "created_at": "2020-01-15T10:00:00Z",
  "updated_at": "2026-11-01T12:00:00Z",
  "pushed_at": "2026-11-05T08:30:00Z",
  "topics": ["flutter", "dart"]
}''';

const String languagesJson = '{"Dart": 7500, "Kotlin": 2000, "Swift": 500}';

const String commitsJson = '''
[
  {
    "sha": "abcdef1234567890",
    "commit": {
      "message": "Agrega pantalla de inicio\\n\\nDetalle del cambio",
      "author": {"name": "Octo Cat", "date": "2026-11-05T08:30:00Z"}
    },
    "author": {"avatar_url": "https://example.com/a.png"}
  },
  {
    "sha": "1234567",
    "commit": {
      "message": "Commit inicial",
      "author": {"name": "Otra Persona", "date": "2026-10-01T09:00:00Z"}
    },
    "author": null
  }
]''';

const String contributorsJson = '''
[
  {"login": "octocat", "avatar_url": "https://example.com/a.png", "contributions": 120},
  {"login": "hubot", "avatar_url": "https://example.com/b.png", "contributions": 15}
]''';

const String contentsJson = '''
[
  {"name": "lib", "path": "lib", "type": "dir", "size": 0},
  {"name": "pubspec.yaml", "path": "pubspec.yaml", "type": "file", "size": 900},
  {"name": ".gitignore", "path": ".gitignore", "type": "file", "size": 120},
  {"name": "README.md", "path": "README.md", "type": "file", "size": 300},
  {"name": ".env", "path": ".env", "type": "file", "size": 40},
  {"name": "Dockerfile", "path": "Dockerfile", "type": "file", "size": 200}
]''';

/// README como lo entrega GitHub: base64 partido en líneas.
String get readmeJson {
  final encoded = base64.encode(utf8.encode('# Demo\n\nHola RepoLens'));
  final half = encoded.length ~/ 2;
  return jsonEncode({
    'name': 'README.md',
    'encoding': 'base64',
    'content': '${encoded.substring(0, half)}\n${encoded.substring(half)}\n',
  });
}

const Map<String, String> _jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

/// Cliente falso que responde a todos los endpoints con datos válidos.
/// [overrides] permite cambiar la respuesta de una ruta concreta
/// (la clave es el final de la ruta, por ejemplo `/commits`).
MockClient successClient({Map<String, http.Response> overrides = const {}}) {
  return MockClient((request) async {
    final path = request.url.path;
    for (final entry in overrides.entries) {
      if (path.endsWith(entry.key)) return entry.value;
    }
    if (path.endsWith('/languages')) return http.Response(languagesJson, 200, headers: _jsonHeaders);
    if (path.endsWith('/commits')) return http.Response(commitsJson, 200, headers: _jsonHeaders);
    if (path.endsWith('/contributors')) {
      return http.Response(contributorsJson, 200, headers: _jsonHeaders);
    }
    if (path.endsWith('/contents')) return http.Response(contentsJson, 200, headers: _jsonHeaders);
    if (path.endsWith('/readme')) return http.Response(readmeJson, 200, headers: _jsonHeaders);
    return http.Response(repoJson, 200, headers: _jsonHeaders);
  });
}

/// Cliente falso que siempre responde con el mismo código de estado.
MockClient statusClient(int status, {Map<String, String> headers = const {}, String body = '{}'}) {
  return MockClient(
    (_) async => http.Response(body, status, headers: {..._jsonHeaders, ...headers}),
  );
}
