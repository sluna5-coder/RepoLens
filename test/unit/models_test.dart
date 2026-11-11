import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/models/analysis_result.dart';
import 'package:repolens/models/commit_info.dart';
import 'package:repolens/models/contributor.dart';
import 'package:repolens/models/favorite.dart';
import 'package:repolens/models/history_entry.dart';
import 'package:repolens/models/language_stat.dart';
import 'package:repolens/models/repo_file.dart';
import 'package:repolens/models/repo_info.dart';
import 'package:repolens/models/user.dart';

import '../mocks/mock_responses.dart';

void main() {
  group('Parseo de modelos', () {
    test('RepoInfo.fromJson lee todos los campos', () {
      final repo = RepoInfo.fromJson(jsonDecode(repoJson) as Map<String, dynamic>);
      expect(repo.fullName, 'octocat/demo');
      expect(repo.ownerLogin, 'octocat');
      expect(repo.stars, 1500);
      expect(repo.forks, 42);
      expect(repo.watchers, 30);
      expect(repo.openIssues, 7);
      expect(repo.license, 'MIT License');
      expect(repo.sizeKb, 2048);
      expect(repo.defaultBranch, 'main');
      expect(repo.createdAt, DateTime.utc(2020, 1, 15, 10));
      expect(repo.topics, ['flutter', 'dart']);
    });

    test('RepoInfo tolera licencia y descripción nulas, y toJson es reversible', () {
      final json = jsonDecode(repoJson) as Map<String, dynamic>
        ..['license'] = null
        ..['description'] = null;
      final repo = RepoInfo.fromJson(json);
      expect(repo.license, isNull);
      expect(repo.description, isNull);
      final again = RepoInfo.fromJson(repo.toJson());
      expect(again.fullName, repo.fullName);
      expect(again.stars, repo.stars);
      expect(again.updatedAt, repo.updatedAt);
    });

    test('LanguageStat.listFromApi calcula porcentajes y ordena', () {
      final list = LanguageStat.listFromApi(jsonDecode(languagesJson) as Map<String, dynamic>);
      expect(list.map((l) => l.name), ['Dart', 'Kotlin', 'Swift']);
      expect(list.first.percent, 75);
      expect(list.fold<double>(0, (s, l) => s + l.percent), closeTo(100, 0.001));
      expect(LanguageStat.listFromApi({}), isEmpty);
      expect(LanguageStat.fromJson(list.first.toJson()).bytes, 7500);
    });

    test('CommitInfo.fromJson lee autor, fecha y título', () {
      final list = (jsonDecode(commitsJson) as List)
          .map((e) => CommitInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(list, hasLength(2));
      expect(list.first.shortSha, 'abcdef1');
      expect(list.first.title, 'Agrega pantalla de inicio');
      expect(list.first.authorName, 'Octo Cat');
      expect(list.first.date, DateTime.utc(2026, 11, 5, 8, 30));
      expect(list.last.avatarUrl, isNull);
      expect(CommitInfo.fromJson(list.first.toJson()).sha, list.first.sha);
    });

    test('Contributor y RepoFile se parsean y serializan', () {
      final contributor = Contributor.fromJson(
          (jsonDecode(contributorsJson) as List).first as Map<String, dynamic>);
      expect(contributor.login, 'octocat');
      expect(contributor.contributions, 120);
      expect(Contributor.fromJson(contributor.toJson()).login, 'octocat');

      final files = (jsonDecode(contentsJson) as List)
          .map((e) => RepoFile.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(files.first.isDir, isTrue);
      expect(files[1].name, 'pubspec.yaml');
      expect(RepoFile.fromJson(files[1].toJson()).size, 900);
    });

    test('User, Favorite y HistoryEntry van y vuelven de una fila SQLite', () {
      final now = DateTime(2026, 11, 11, 9);
      final user = User(
          id: 1, name: 'Demo', email: 'demo@repolens.app', passwordHash: 'h', salt: 's', createdAt: now);
      expect(User.fromJson(user.toJson()).email, 'demo@repolens.app');

      final favorite = Favorite(
          id: 2, userId: 1, fullName: 'a/b', note: 'nota', createdAt: now, updatedAt: now);
      final favoriteAgain = Favorite.fromJson(favorite.toJson());
      expect(favoriteAgain.note, 'nota');
      expect(favoriteAgain.updatedAt, now);

      final entry = HistoryEntry(
          id: 3, userId: 1, fullName: 'a/b', jsonSnapshot: '{}', healthScore: 80, analyzedAt: now);
      expect(HistoryEntry.fromJson(entry.toJson()).healthScore, 80);
    });

    test('AnalysisResult conserva todo al serializar (snapshot de historial)', () {
      final repo = RepoInfo.fromJson(jsonDecode(repoJson) as Map<String, dynamic>);
      final result = AnalysisResult(
        repo: repo,
        languages: const [LanguageStat(name: 'Dart', bytes: 10, percent: 100)],
        commits: const [],
        contributors: const [],
        files: const [RepoFile(name: '.env', path: '.env', type: 'file', size: 1)],
        readme: '# Hola',
        stacks: const ['Flutter/Dart'],
        healthScore: 65,
        healthChecks: const [HealthCheck(label: 'Tiene README', passed: true, points: 20)],
        alerts: const ['.env'],
        analyzedAt: DateTime(2026, 11, 11),
      );
      final again = AnalysisResult.fromJson(
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>);
      expect(again.repo.fullName, 'octocat/demo');
      expect(again.healthScore, 65);
      expect(again.stacks, ['Flutter/Dart']);
      expect(again.alerts, ['.env']);
      expect(again.healthChecks.single.passed, isTrue);
      expect(again.readme, '# Hola');
    });
  });
}
