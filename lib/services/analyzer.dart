import '../models/analysis_result.dart';
import '../models/repo_insights.dart';
import '../models/repo_file.dart';
import 'github_service.dart';

/// Lógica de negocio propia de RepoLens: no hace peticiones, solo analiza los
/// datos ya descargados. Por eso todos sus métodos son estáticos y puros,
/// fáciles de probar.
class Analyzer {
  /// Archivo de la raíz -> tecnología que delata.
  static const Map<String, String> _stackByFile = {
    'pubspec.yaml': 'Flutter/Dart',
    'package.json': 'Node/JS',
    'requirements.txt': 'Python',
    'pyproject.toml': 'Python',
    'build.gradle': 'Android/Kotlin/Java',
    'build.gradle.kts': 'Android/Kotlin/Java',
    'pom.xml': 'Maven',
    'cargo.toml': 'Rust',
    'go.mod': 'Go',
    'composer.json': 'PHP',
    'dockerfile': 'Docker',
  };

  /// Nombres exactos de archivos sensibles.
  static const Set<String> _sensitiveNames = {
    '.env',
    'google-services.json',
    'googleservice-info.plist',
    'key.properties',
    'id_rsa',
    'credentials.json',
  };

  /// Extensiones de archivos sensibles (llaves y almacenes de claves).
  static const List<String> _sensitiveExtensions = ['.jks', '.keystore', '.pem'];

  /// Frameworks y herramientas que delata un archivo por su nombre (en
  /// cualquier carpeta). Se compara con el inicio del nombre para cubrir
  /// variantes como `vite.config.ts` o `vite.config.js`.
  static const Map<String, String> _toolByPrefix = {
    'vite.config.': 'Vite',
    'next.config.': 'Next.js',
    'nuxt.config.': 'Nuxt',
    'angular.json': 'Angular',
    'svelte.config.': 'Svelte',
    'tailwind.config.': 'Tailwind CSS',
    'webpack.config.': 'Webpack',
    'tsconfig.json': 'TypeScript',
    'docker-compose.': 'Docker Compose',
    'compose.yaml': 'Docker Compose',
    'firebase.json': 'Firebase',
    'androidmanifest.xml': 'Android',
    'manage.py': 'Django',
    'artisan': 'Laravel',
    'gemfile': 'Ruby',
    'cmakelists.txt': 'CMake',
    'makefile': 'Make',
  };

  /// Lenguajes que se reportan cuando no hay ningún archivo de configuración.
  static const Map<String, String> _techByExtension = {
    '.html': 'HTML',
    '.css': 'CSS',
    '.js': 'JavaScript',
    '.ts': 'TypeScript',
    '.py': 'Python',
    '.java': 'Java',
    '.kt': 'Kotlin',
    '.php': 'PHP',
    '.cs': 'C#',
    '.c': 'C',
    '.cpp': 'C++',
    '.go': 'Go',
    '.rs': 'Rust',
    '.rb': 'Ruby',
    '.swift': 'Swift',
    '.dart': 'Dart',
    '.ipynb': 'Jupyter Notebook',
    '.sql': 'SQL',
    '.ino': 'Arduino',
  };

  /// Detecta el stack por los archivos del repositorio (sin repetir).
  /// Acepta solo la raíz o el árbol completo. Si no hay archivos de
  /// configuración, usa las extensiones de código como respaldo.
  static List<String> detectStack(List<RepoFile> files) {
    final found = <String>{};
    final codeFiles = files.where((f) => !f.isDir).toList();
    for (final file in codeFiles) {
      final name = file.name.toLowerCase();
      final stack = _stackByFile[name];
      if (stack != null) found.add(stack);
      if (name.endsWith('.csproj')) found.add('.NET');
      for (final entry in _toolByPrefix.entries) {
        if (name.startsWith(entry.key)) found.add(entry.value);
      }
      if (file.path.toLowerCase().startsWith('.github/workflows/')) {
        found.add('GitHub Actions');
      }
    }
    // En Flutter, las carpetas android/, windows/ y linux/ son plantilla del
    // framework: no se reportan como stacks aparte.
    if (found.contains('Flutter/Dart')) {
      found.removeAll(const ['Android/Kotlin/Java', 'Android', 'CMake']);
    }
    if (found.isEmpty) {
      for (final file in codeFiles) {
        final tech = _techByExtension[_extension(file.name)];
        if (tech != null) found.add(tech);
      }
    }
    return found.toList();
  }

  /// Lista los archivos sensibles que no deberían estar en un repo público.
  /// Con el árbol completo devuelve la ruta; con la raíz, el nombre.
  static List<String> securityAlerts(List<RepoFile> files) {
    return files.where((f) => !f.isDir).where((f) {
      final lower = f.name.toLowerCase();
      return _sensitiveNames.contains(lower) ||
          _sensitiveExtensions.any(lower.endsWith);
    }).map((f) => f.path.isEmpty ? f.name : f.path).toList();
  }

  /// Extensión en minúsculas con punto (".dart"), o "" si no tiene.
  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot).toLowerCase();
  }

  /// Analiza la estructura completa: tamaño, extensiones, archivos pesados,
  /// buenas prácticas presentes y recomendaciones. Devuelve `null` si no se
  /// pudo leer el árbol.
  static RepoInsights? insights(RepoData data, List<HealthCheck> checks,
      List<String> alerts, {DateTime? now}) {
    if (data.tree.isEmpty) return null;
    final files = data.tree.where((f) => !f.isDir).toList();
    final paths = data.tree.map((f) => f.path.toLowerCase()).toList();
    final names = files.map((f) => f.name.toLowerCase()).toSet();

    final byExtension = <String, int>{};
    for (final f in files) {
      final ext = _extension(f.name);
      final key = ext.isEmpty ? '(sin extensión)' : ext;
      byExtension[key] = (byExtension[key] ?? 0) + 1;
    }
    final extensions = byExtension.entries
        .map((e) => ExtensionStat(extension: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final largest = [...files]..sort((a, b) => b.size.compareTo(a.size));

    bool anyPath(bool Function(String p) test) => paths.any(test);
    final hasTests = anyPath((p) =>
        p.split('/').any((s) => s == 'test' || s == 'tests' || s == '__tests__' || s == 'spec') ||
        RegExp(r'(_test|\.test|\.spec|test_)[^/]*$').hasMatch(p));
    final hasCi = anyPath((p) =>
        p.startsWith('.github/workflows/') ||
        p == '.gitlab-ci.yml' ||
        p == '.travis.yml' ||
        p == 'jenkinsfile' ||
        p.startsWith('.circleci/'));
    final hasDocker = names.contains('dockerfile') || names.any((n) => n.startsWith('docker-compose'));
    final hasDocs = anyPath((p) => p.startsWith('docs/') || p.startsWith('doc/'));
    final hasContributing = names.contains('contributing.md');
    final hasChangelog = names.any((n) => n.startsWith('changelog'));

    final signals = [
      RepoSignal(label: 'Pruebas automatizadas', present: hasTests),
      RepoSignal(label: 'Integración continua (CI)', present: hasCi),
      RepoSignal(label: 'Docker', present: hasDocker),
      RepoSignal(label: 'Carpeta de documentación', present: hasDocs),
      RepoSignal(label: 'Guía de contribución', present: hasContributing),
      RepoSignal(label: 'Registro de cambios', present: hasChangelog),
    ];

    final today = now ?? DateTime.now();
    final pushed = data.repo.pushedAt;
    // README que existe pero en una subcarpeta: GitHub no lo muestra en la portada.
    final nestedReadme = data.tree
        .where((f) => !f.isDir && f.path.contains('/') && f.name.toLowerCase().startsWith('readme'))
        .map((f) => f.path)
        .firstOrNull;
    final recommendations = <String>[
      for (final c in checks.where((c) => !c.passed))
        if (c.label == 'Tiene README' && nestedReadme != null)
          'El README está en $nestedReadme: muévelo a la raíz para que GitHub lo muestre en la portada.'
        else if (_advice[c.label] != null)
          _advice[c.label]!,
      if (!hasTests) 'Agrega pruebas automatizadas para comprobar que el código funciona.',
      if (!hasCi) 'Configura GitHub Actions para correr las pruebas en cada push.',
      if (alerts.isNotEmpty)
        'Quita del repositorio los archivos sensibles y cambia las claves expuestas.',
      if (largest.isNotEmpty && largest.first.size > 5 * 1024 * 1024)
        'Hay archivos de más de 5 MB: considera Git LFS o sacarlos del repositorio.',
      if (pushed != null && today.difference(pushed).inDays > 365)
        'No tiene cambios desde hace más de un año: puede estar abandonado.',
    ];

    return RepoInsights(
      totalFiles: files.length,
      totalDirs: data.tree.length - files.length,
      totalBytes: files.fold(0, (sum, f) => sum + f.size),
      maxDepth: data.tree.fold(0, (m, f) {
        final depth = '/'.allMatches(f.path).length;
        return depth > m ? depth : m;
      }),
      extensions: extensions.take(8).toList(),
      largestFiles: largest
          .take(5)
          .where((f) => f.size > 0)
          .map((f) => FileSize(path: f.path, size: f.size))
          .toList(),
      signals: signals,
      recommendations: recommendations,
      truncated: data.treeTruncated,
    );
  }

  /// Consejo para cada criterio de salud no cumplido.
  static const Map<String, String> _advice = {
    'Tiene README': 'Agrega un README.md que explique qué hace el proyecto y cómo usarlo.',
    'Tiene licencia': 'Elige una licencia (por ejemplo MIT) para que otros sepan cómo pueden usarlo.',
    'Tiene .gitignore': 'Agrega un .gitignore para no subir archivos generados ni secretos.',
    'Tiene descripción': 'Escribe una descripción corta en la página del repositorio.',
    'Commit en los últimos 90 días': 'El proyecto no tiene cambios recientes.',
    'Más de un contribuidor': 'Solo tiene un contribuidor: invitar revisores ayuda a la calidad.',
    'Temas definidos': 'Agrega temas (topics) para que el repositorio sea fácil de encontrar.',
  };

  /// Calcula los 7 criterios de salud. Los puntos suman 100.
  /// [now] se puede inyectar para que las pruebas sean deterministas.
  static List<HealthCheck> healthChecks(RepoData data, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final names = data.files.map((f) => f.name.toLowerCase()).toSet();
    final lastCommit = data.commits.isNotEmpty
        ? (data.commits.first.date ?? data.repo.pushedAt)
        : data.repo.pushedAt;
    final recent =
        lastCommit != null && today.difference(lastCommit).inDays <= 90;
    final description = data.repo.description?.trim() ?? '';

    return [
      HealthCheck(
        label: 'Tiene README',
        passed: data.readme != null || names.any((n) => n.startsWith('readme')),
        points: 20,
      ),
      HealthCheck(label: 'Tiene licencia', passed: data.repo.license != null, points: 15),
      // Un .gitignore en la carpeta del proyecto también protege el repo.
      HealthCheck(
        label: 'Tiene .gitignore',
        passed: names.contains('.gitignore') ||
            data.tree.any((f) => f.name.toLowerCase() == '.gitignore'),
        points: 10,
      ),
      HealthCheck(label: 'Tiene descripción', passed: description.isNotEmpty, points: 15),
      HealthCheck(label: 'Commit en los últimos 90 días', passed: recent, points: 20),
      HealthCheck(
        label: 'Más de un contribuidor',
        passed: data.contributors.length > 1,
        points: 10,
      ),
      HealthCheck(label: 'Temas definidos', passed: data.repo.topics.isNotEmpty, points: 10),
    ];
  }

  /// Suma los puntos de los criterios cumplidos (0 a 100).
  static int healthScore(List<HealthCheck> checks) =>
      checks.where((c) => c.passed).fold(0, (sum, c) => sum + c.points);

  /// Une los datos de la API con el análisis propio en un informe completo.
  static AnalysisResult build(RepoData data, {DateTime? now}) {
    final checks = healthChecks(data, now: now);
    // Con el árbol completo se revisan todas las carpetas; si no, solo la raíz.
    final scope = data.tree.isNotEmpty ? data.tree : data.files;
    final alerts = securityAlerts(scope);
    return AnalysisResult(
      repo: data.repo,
      languages: data.languages,
      commits: data.commits,
      contributors: data.contributors,
      files: data.files,
      readme: data.readme,
      stacks: detectStack(scope),
      healthScore: healthScore(checks),
      healthChecks: checks,
      alerts: alerts,
      analyzedAt: now ?? DateTime.now(),
      insights: insights(data, checks, alerts, now: now),
    );
  }
}
