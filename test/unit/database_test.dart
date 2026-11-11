import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/exceptions.dart';
import 'package:repolens/data/cache_repository.dart';
import 'package:repolens/data/favorite_repository.dart';
import 'package:repolens/data/history_repository.dart';
import 'package:repolens/data/user_repository.dart';
import 'package:repolens/models/analysis_result.dart';
import 'package:repolens/models/user.dart';
import 'package:repolens/providers/analysis_provider.dart';
import 'package:repolens/providers/favorites_provider.dart';
import 'package:repolens/providers/history_provider.dart';
import 'package:repolens/services/connectivity_service.dart';
import 'package:repolens/services/github_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks/mock_responses.dart';

/// Servicio de conectividad falso para simular con o sin red.
class FakeConnectivity extends ConnectivityService {
  FakeConnectivity(this.online);
  bool online;

  @override
  Future<bool> hasConnection() async => online;
}

/// Pruebas de integración contra SQLite real (motor FFI de escritorio):
/// verifican el esquema, los repositorios y los providers que los usan.
void main() {
  late int userId;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = Directory.systemTemp.createTempSync('repolens_test_');
    await databaseFactory.setDatabasesPath(dir.path);
    userId = await UserRepository().insert(User(
      name: 'Prueba',
      email: 'prueba@repolens.app',
      passwordHash: 'hash',
      salt: 'salt',
      createdAt: DateTime(2026, 11, 11),
    ));
  });

  test('users: inserta, consulta y rechaza email duplicado (UNIQUE)', () async {
    final users = UserRepository();
    expect((await users.findByEmail('prueba@repolens.app'))?.id, userId);
    expect((await users.findById(userId))?.name, 'Prueba');
    expect(await users.findByEmail('nadie@repolens.app'), isNull);
    expect(
      users.insert(User(
        name: 'Otro',
        email: 'prueba@repolens.app',
        passwordHash: 'h',
        salt: 's',
        createdAt: DateTime(2026, 11, 11),
      )),
      throwsA(isA<DatabaseAppException>()),
    );
  });

  test('favorites: CRUD completo (agregar, consultar, editar nota, eliminar)', () async {
    final favorites = FavoritesProvider(FavoriteRepository());

    // CREATE
    expect(await favorites.add(userId, 'flutter/flutter', note: 'Nota inicial'), isTrue);
    // READ (desde SQLite, con un provider nuevo)
    final reloaded = FavoritesProvider(FavoriteRepository());
    await reloaded.load(userId);
    expect(reloaded.items.single.fullName, 'flutter/flutter');
    expect(reloaded.items.single.note, 'Nota inicial');
    expect(reloaded.find('FLUTTER/flutter'), isNotNull);

    // UPDATE
    expect(await reloaded.updateNote(reloaded.items.single, 'Nota editada'), isTrue);
    await favorites.load(userId);
    expect(favorites.items.single.note, 'Nota editada');
    expect(
      favorites.items.single.updatedAt.isBefore(favorites.items.single.createdAt),
      isFalse,
    );

    // DELETE
    expect(await favorites.remove(favorites.items.single.id!), isTrue);
    await reloaded.load(userId);
    expect(reloaded.items, isEmpty);
  });

  test('análisis: consulta la API, guarda en historial y luego usa la caché', () async {
    var requests = 0;
    final client = successClient();
    final counting = GithubService(
      client: client,
      tokenProvider: () async {
        requests++;
        return null;
      },
    );
    final connectivity = FakeConnectivity(true);
    final analysis = AnalysisProvider(
      github: counting,
      cache: CacheRepository(),
      history: HistoryRepository(),
      connectivity: connectivity,
    );

    final first = await analysis.analyze('https://github.com/octocat/demo', userId: userId);
    expect(analysis.status, AnalysisStatus.success);
    expect(first!.fromCache, isFalse);
    expect(first.stacks, containsAll(['Flutter/Dart', 'Docker']));
    expect(first.alerts, ['.env']);
    expect(requests, 6); // los 6 endpoints

    // Segunda vez: sale de la caché, sin peticiones y aunque no haya red.
    connectivity.online = false;
    final second = await analysis.analyze('github.com/octocat/demo', userId: userId);
    expect(second!.fromCache, isTrue);
    expect(requests, 6);

    // Historial: consultar, reabrir snapshot, eliminar uno y vaciar.
    final history = HistoryProvider(HistoryRepository());
    await history.load(userId);
    expect(history.entries, hasLength(2));
    expect(history.entries.first.healthScore, first.healthScore);
    final snapshot = AnalysisResult.fromJson(
        jsonDecode(history.entries.first.jsonSnapshot) as Map<String, dynamic>);
    expect(snapshot.repo.fullName, 'octocat/demo');

    expect(await history.remove(history.entries.first.id!), isTrue);
    await history.load(userId);
    expect(history.entries, hasLength(1));

    expect(await history.clear(userId), isTrue);
    await history.load(userId);
    expect(history.entries, isEmpty);
  });

  test('análisis: sin conexión y sin caché muestra NoConnectionException', () async {
    final analysis = AnalysisProvider(
      github: GithubService(client: successClient()),
      cache: CacheRepository(),
      history: HistoryRepository(),
      connectivity: FakeConnectivity(false),
    );
    final result = await analysis.analyze('https://github.com/otro/repo', userId: userId);
    expect(result, isNull);
    expect(analysis.status, AnalysisStatus.error);
    expect(analysis.error, isA<NoConnectionException>());
  });

  test('análisis: repo inexistente (404) y URL inválida dejan error con mensaje', () async {
    final analysis = AnalysisProvider(
      github: GithubService(client: statusClient(404)),
      cache: CacheRepository(),
      history: HistoryRepository(),
      connectivity: FakeConnectivity(true),
    );
    await analysis.analyze('https://github.com/no/existe', userId: userId);
    expect(analysis.error, isA<NotFoundException>());
    expect(analysis.error!.message, contains('No se encontró el repositorio'));

    await analysis.analyze('esto no es una url', userId: userId);
    expect(analysis.error, isA<InvalidUrlException>());

    final history = HistoryProvider(HistoryRepository());
    await history.load(userId);
    expect(history.entries, isEmpty); // los errores no se guardan en el historial
  });

  test('cache: una entrada vencida (más de 30 min) no se devuelve', () async {
    final cache = CacheRepository();
    await cache.put('Viejo/Repo', '{"a":1}');
    expect(await cache.get('viejo/repo'), '{"a":1}');

    final db = await databaseFactory.openDatabase(
        '${await databaseFactory.getDatabasesPath()}${Platform.pathSeparator}repolens.db');
    await db.update(
      'cache',
      {'fetched_at': DateTime.now().subtract(const Duration(minutes: 31)).toIso8601String()},
      where: 'full_name = ?',
      whereArgs: ['viejo/repo'],
    );
    expect(await cache.get('viejo/repo'), isNull);

    await cache.clear();
    expect(await cache.get('octocat/demo'), isNull);
  });
}
