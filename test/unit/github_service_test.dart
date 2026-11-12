import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:repolens/core/exceptions.dart';
import 'package:repolens/services/github_service.dart';

import '../mocks/mock_responses.dart';

void main() {
  group('GithubService con MockClient', () {
    test('fetchAll incluye el árbol completo del repositorio', () async {
      final service = GithubService(client: successClient());
      final data = await service.fetchAll('octocat/demo');
      expect(data.tree.where((f) => !f.isDir).length, 8);
      expect(data.tree.firstWhere((f) => f.path == 'lib/main.dart').name, 'main.dart');
      expect(data.treeTruncated, isFalse);
    });

    test('fetchAll descarga y parsea todos los endpoints', () async {
      final service = GithubService(client: successClient());
      final data = await service.fetchAll('octocat/demo');
      expect(data.repo.fullName, 'octocat/demo');
      expect(data.languages.first.name, 'Dart');
      expect(data.commits, hasLength(2));
      expect(data.contributors, hasLength(2));
      expect(data.files, hasLength(6));
      expect(data.readme, '# Demo\n\nHola RepoLens'); // base64 decodificado
    });

    test('consulta la URL correcta y envía el token si existe', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(repoJson, 200);
      });
      final service = GithubService(client: client, tokenProvider: () async => 'token-de-prueba');
      await service.getRepo('octocat/demo');
      expect(captured.url.toString(), 'https://api.github.com/repos/octocat/demo');
      expect(captured.headers['Authorization'], 'Bearer token-de-prueba');
    });

    test('404 lanza NotFoundException', () {
      final service = GithubService(client: statusClient(404));
      expect(service.getRepo('no/existe'), throwsA(isA<NotFoundException>()));
    });

    test('403 sin peticiones restantes lanza RateLimitException con la hora de reinicio',
        () async {
      final service = GithubService(
        client: statusClient(403, headers: {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': '1794000000',
        }),
      );
      try {
        await service.getRepo('octocat/demo');
        fail('Debió lanzar RateLimitException');
      } on RateLimitException catch (e) {
        expect(e.resetAt, DateTime.fromMillisecondsSinceEpoch(1794000000 * 1000, isUtc: true));
        expect(e.message, contains('Se reinicia a las'));
      }
    });

    test('429 también lanza RateLimitException', () {
      final service = GithubService(client: statusClient(429));
      expect(service.getRepo('octocat/demo'), throwsA(isA<RateLimitException>()));
    });

    test('sin conexión (SocketException) lanza NoConnectionException', () {
      final client = MockClient((_) async => throw const SocketException('sin red'));
      final service = GithubService(client: client);
      expect(service.getRepo('octocat/demo'), throwsA(isA<NoConnectionException>()));
    });

    test('una respuesta lenta lanza RequestTimeoutException', () {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(repoJson, 200);
      });
      final service = GithubService(client: client, timeout: const Duration(milliseconds: 20));
      expect(service.getRepo('octocat/demo'), throwsA(isA<RequestTimeoutException>()));
    });

    test('409 en commits (repo vacío) lanza EmptyRepoException', () {
      final service = GithubService(
        client: successClient(overrides: {'/commits': http.Response('{}', 409)}),
      );
      expect(service.fetchAll('octocat/vacio'), throwsA(isA<EmptyRepoException>()));
    });

    test('JSON inesperado lanza UnexpectedJsonException', () {
      final malformed = GithubService(client: statusClient(200, body: 'esto no es json'));
      expect(malformed.getRepo('octocat/demo'), throwsA(isA<UnexpectedJsonException>()));

      final wrongShape = GithubService(client: statusClient(200, body: '{"otra": "forma"}'));
      expect(wrongShape.getRepo('octocat/demo'), throwsA(isA<UnexpectedJsonException>()));
    });

    test('un repo sin README devuelve null en vez de fallar', () async {
      final service = GithubService(
        client: successClient(overrides: {'/readme': http.Response('{}', 404)}),
      );
      final data = await service.fetchAll('octocat/demo');
      expect(data.readme, isNull);
    });
  });
}
