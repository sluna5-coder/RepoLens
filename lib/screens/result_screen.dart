import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/readme_formatter.dart';
import '../core/theme.dart';
import '../core/url_policy.dart';
import '../core/utils.dart';
import '../core/validators.dart';
import '../models/analysis_result.dart';
import '../models/repo_insights.dart';
import '../app.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/analyzer.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Pide una nota (máx. 300 caracteres) en un diálogo. Devuelve `null` si se
/// cancela. Se usa al agregar un favorito y al editar su nota.
Future<String?> askNote(BuildContext context, {String initial = '', required String title}) {
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          key: const Key('note_field'),
          controller: controller,
          maxLines: 4,
          maxLength: AppConstants.maxNoteLength,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: Validators.note,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            hintText: '¿Por qué te interesa este repo?',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, controller.text.trim());
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

/// Informe de un repositorio en seis pestañas.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final AnalysisResult result;

  /// Agrega o quita el repo de favoritos, con confirmación y SnackBar.
  Future<void> _toggleFavorite(BuildContext context) async {
    final favorites = context.read<FavoritesProvider>();
    final userId = context.read<AuthProvider>().user!.id!;
    final existing = favorites.find(result.repo.fullName);

    if (existing == null) {
      final note = await askNote(context, title: 'Agregar a favoritos');
      if (note == null || !context.mounted) return;
      final ok = await favorites.add(userId, result.repo.fullName, note: note);
      if (!context.mounted) return;
      showSnack(context, ok ? 'Guardado en favoritos' : 'No se pudo guardar el favorito');
    } else {
      final confirmed = await confirmDialog(
        context,
        title: 'Quitar de favoritos',
        message: '¿Quitar ${result.repo.fullName} de tus favoritos?',
        confirmLabel: 'Quitar',
      );
      if (!confirmed || !context.mounted) return;
      final ok = await favorites.remove(existing.id!);
      if (!context.mounted) return;
      showSnack(context, ok ? 'Eliminado de favoritos' : 'No se pudo eliminar el favorito');
    }
  }

  /// Vuelve a consultar la API sin usar la caché y reemplaza el informe.
  Future<void> _refresh(BuildContext context) async {
    final analysis = context.read<AnalysisProvider>();
    final history = context.read<HistoryProvider>();
    final userId = context.read<AuthProvider>().user!.id!;
    showSnack(context, 'Actualizando el informe');
    final fresh =
        await analysis.analyze(result.repo.fullName, userId: userId, force: true);
    if (!context.mounted) return;
    if (fresh == null) {
      showSnack(context, analysis.error?.message ?? 'No se pudo actualizar');
      return;
    }
    await history.load(userId);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.result, arguments: fresh);
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        context.watch<FavoritesProvider>().find(result.repo.fullName) != null;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(result.repo.fullName),
          actions: [
            IconButton(
              key: const Key('refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: () => _refresh(context),
            ),
            Semantics(
              label: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
              button: true,
              child: IconButton(
                key: const Key('favorite_button'),
                icon: Icon(isFavorite ? Icons.star : Icons.star_outline),
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                onPressed: () => _toggleFavorite(context),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Lenguajes'),
              Tab(text: 'Commits'),
              Tab(text: 'Archivos'),
              Tab(text: 'README'),
              Tab(text: 'Salud'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(result),
            _LanguagesTab(result),
            _CommitsTab(result),
            _FilesTab(result),
            _ReadmeTab(result),
            _HealthTab(result),
          ],
        ),
      ),
    );
  }
}

/// Pestaña Resumen: datos generales, stack, temas y contribuidores.
class _SummaryTab extends StatelessWidget {
  const _SummaryTab(this.result);
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final repo = result.repo;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidth(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      repo.avatarUrl.isEmpty ? null : NetworkImage(repo.avatarUrl),
                  onBackgroundImageError: repo.avatarUrl.isEmpty ? null : (_, _) {},
                  child: repo.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.name, style: theme.textTheme.headlineSmall),
                      Text('de ${repo.ownerLogin}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                HealthBadge(score: result.healthScore),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (repo.description?.trim().isNotEmpty ?? false)
                  ? repo.description!
                  : 'Sin descripción',
              style: theme.textTheme.bodyLarge,
            ),
            if (result.fromCache) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.cached, size: 18),
                label: Text('Desde caché · ${Fmt.dateTime(result.analyzedAt)}'),
              ),
            ],
            if (result.alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AlertsCard(result.alerts),
            ],
            const SizedBox(height: 12),
            // LayoutBuilder: 2 columnas en teléfono, 4 en tableta.
            LayoutBuilder(
              builder: (context, constraints) => GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 600 ? 4 : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 112,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatTile(
                      icon: Icons.star, label: 'Estrellas', value: Fmt.compact(repo.stars)),
                  StatTile(icon: Icons.call_split, label: 'Forks', value: Fmt.compact(repo.forks)),
                  StatTile(
                      icon: Icons.visibility,
                      label: 'Watchers',
                      value: Fmt.compact(repo.watchers)),
                  StatTile(
                      icon: Icons.bug_report,
                      label: 'Issues abiertos',
                      value: Fmt.compact(repo.openIssues)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Stack detectado', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (result.stacks.isEmpty)
              const Text('No se reconoció ninguna tecnología en los archivos del repositorio')
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final s in result.stacks)
                    Chip(avatar: const Icon(Icons.layers, size: 18), label: Text(s)),
                ],
              ),
            if (result.insights != null) ...[
              const SizedBox(height: 12),
              Text('Estructura', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              _StructureCard(result.insights!),
            ],
            if (repo.topics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Temas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [for (final t in repo.topics) Chip(label: Text(t))],
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _row(Icons.balance, 'Licencia', repo.license ?? 'Sin licencia'),
                  _row(Icons.sd_storage, 'Tamaño', Fmt.sizeKb(repo.sizeKb)),
                  _row(Icons.account_tree, 'Rama por defecto', repo.defaultBranch),
                  _row(Icons.event, 'Creado', Fmt.date(repo.createdAt)),
                  _row(Icons.update, 'Actualizado', Fmt.date(repo.updatedAt)),
                ],
              ),
            ),
            if (result.contributors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Contribuidores principales', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final c in result.contributors)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: c.avatarUrl.isEmpty ? null : NetworkImage(c.avatarUrl),
                    onBackgroundImageError: c.avatarUrl.isEmpty ? null : (_, _) {},
                  ),
                  title: Text(c.login),
                  trailing: Text('${c.contributions} commits'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value),
      );
}

/// Tarjeta roja con los archivos sensibles encontrados.
class _AlertsCard extends StatelessWidget {
  const _AlertsCard(this.alerts);
  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
        title: Text(
          'Alertas de seguridad (${alerts.length})',
          style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Archivos sensibles: ${alerts.take(3).join(', ')}'
          '${alerts.length > 3 ? ' y ${alerts.length - 3} más' : ''}',
          style: TextStyle(color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}

/// Pestaña Lenguajes: gráfica de pastel (fl_chart) y leyenda con porcentajes.
class _LanguagesTab extends StatelessWidget {
  const _LanguagesTab(this.result);
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final languages = result.languages;
    if (languages.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Sin lenguajes',
        message: 'GitHub no detectó lenguajes en este repositorio.',
      );
    }
    Color colorAt(int i) => AppTheme.chartColors[i % AppTheme.chartColors.length];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidth(
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    for (var i = 0; i < languages.length; i++)
                      PieChartSectionData(
                        value: languages[i].percent,
                        color: colorAt(i),
                        radius: 70,
                        // Solo se rotulan las rebanadas grandes para que se lean.
                        title: languages[i].percent >= 8
                            ? '${languages[i].percent.toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < languages.length; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(radius: 8, backgroundColor: colorAt(i)),
                title: Text(languages[i].name),
                trailing: Text('${languages[i].percent.toStringAsFixed(1)} %'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pestaña Commits: los 10 más recientes.
class _CommitsTab extends StatelessWidget {
  const _CommitsTab(this.result);
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    if (result.commits.isEmpty) {
      return const EmptyState(
        icon: Icons.commit,
        title: 'Sin commits',
        message: 'Este repositorio todavía no tiene commits.',
      );
    }
    return MaxWidth(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: result.commits.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = result.commits[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: c.avatarUrl == null ? null : NetworkImage(c.avatarUrl!),
              onBackgroundImageError: c.avatarUrl == null ? null : (_, _) {},
              child: c.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c.authorName} · ${Fmt.dateTime(c.date)} · ${c.shortSha}'),
          );
        },
      ),
    );
  }
}

/// Pestaña Archivos: contenido de la raíz, marcando los sensibles.
class _FilesTab extends StatelessWidget {
  const _FilesTab(this.result);
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    if (result.files.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open,
        title: 'Sin archivos',
        message: 'La raíz del repositorio está vacía.',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    // Carpetas primero, luego archivos, en orden alfabético.
    final files = [...result.files]..sort((a, b) {
        if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final sensitive = Analyzer.securityAlerts(files).toSet();
    final insights = result.insights;
    final header = insights == null ? 0 : 1;
    return MaxWidth(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: files.length + header,
        itemBuilder: (context, index) {
          if (index < header) return _FilesSummary(insights!);
          final f = files[index - header];
          final risky = sensitive.contains(f.name);
          return ListTile(
            dense: true,
            leading: Icon(
              risky
                  ? Icons.warning_amber_rounded
                  : (f.isDir ? Icons.folder : Icons.insert_drive_file_outlined),
              color: risky ? scheme.error : (f.isDir ? scheme.primary : null),
            ),
            title: Text(f.name),
            subtitle: risky ? const Text('Archivo sensible') : null,
            trailing: f.isDir ? null : Text(Fmt.sizeKb((f.size / 1024).ceil())),
          );
        },
      ),
    );
  }
}

/// Pestaña README: Markdown renderizado con flutter_markdown.
///
/// El README se recorta y se formatea una sola vez (no en cada build) y en
/// móvil fuera del hilo de la interfaz con `compute`.
class _ReadmeTab extends StatefulWidget {
  const _ReadmeTab(this.result);
  final AnalysisResult result;

  @override
  State<_ReadmeTab> createState() => _ReadmeTabState();
}

class _ReadmeTabState extends State<_ReadmeTab> with AutomaticKeepAliveClientMixin {
  Future<({String text, bool truncated})>? _formatted;
  late final ReadmeFormatter _formatter = ReadmeFormatter(
    fullName: widget.result.repo.fullName,
    branch: widget.result.repo.defaultBranch,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final readme = widget.result.readme;
    if (readme != null && readme.trim().isNotEmpty) {
      // Convierte el HTML de GitHub a Markdown y vuelve absolutas las rutas.
      final args = [widget.result.repo.fullName, widget.result.repo.defaultBranch, readme];
      _formatted = kIsWeb ? Future(() => formatReadme(args)) : compute(formatReadme, args);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formatted = _formatted;
    if (formatted == null) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'Sin README',
        message: 'Este repositorio no tiene un archivo README.',
      );
    }
    return FutureBuilder<({String text, bool truncated})>(
      future: formatted,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return snapshot.hasError
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'README no disponible',
                  message: 'No se pudo preparar el README para mostrarlo.',
                )
              : const LoadingView(message: 'Preparando README...');
        }
        return MaxWidth(
          maxWidth: 900,
          child: Column(
            children: [
              if (data.truncated)
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.content_cut),
                  title: Text('README recortado'),
                  subtitle: Text('Es muy largo: solo se muestran los primeros 200 KB.'),
                ),
              Expanded(
                child: Markdown(
                  data: data.text,
                  padding: const EdgeInsets.all(16),
                  onTapLink: (_, href, _) => _openLink(context, href),
                  sizedImageBuilder: (config) => _ReadmeImage(
                    uri: config.uri.hasScheme
                        ? config.uri
                        : Uri.parse(_formatter.resolveImage(config.uri.toString())),
                    width: config.width,
                    height: config.height,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Abre un enlace del README en el navegador. Solo acepta http, https y
/// mailto; los anclas internas (#seccion) se ignoran. Si el destino no es
/// GitHub se muestra antes el host real, porque el texto del enlace puede
/// decir otra cosa.
Future<void> _openLink(BuildContext context, String? href) async {
  final uri = href == null ? null : Uri.tryParse(href);
  if (uri == null || !const {'http', 'https', 'mailto'}.contains(uri.scheme)) return;
  if (!UrlPolicy.isGithubLink(uri)) {
    final target = uri.scheme == 'mailto' ? uri.path : uri.host;
    final confirmed = await confirmDialog(
      context,
      title: 'Abrir enlace externo',
      message: 'Este enlace lleva a $target, fuera de GitHub. ¿Quieres abrirlo?',
      confirmLabel: 'Abrir',
    );
    if (!confirmed) return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) showSnack(context, 'No se pudo abrir el enlace');
}

/// Imagen del README: PNG, JPG, GIF o SVG, con el tamaño pedido en el HTML.
/// Si no carga, no ocupa espacio. Solo se cargan solas las de hosts de
/// confianza ([UrlPolicy.isTrustedImage]); las demás esperan un toque.
class _ReadmeImage extends StatefulWidget {
  const _ReadmeImage({required this.uri, this.width, this.height});
  final Uri uri;
  final double? width;
  final double? height;

  @override
  State<_ReadmeImage> createState() => _ReadmeImageState();
}

class _ReadmeImageState extends State<_ReadmeImage> {
  late bool _load = UrlPolicy.isTrustedImage(widget.uri);

  @override
  Widget build(BuildContext context) {
    final uri = widget.uri;
    final width = widget.width;
    final height = widget.height;
    if (!uri.scheme.startsWith('http')) return const SizedBox.shrink();
    if (!_load) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _load = true),
          icon: const Icon(Icons.image_outlined),
          label: Text('Imagen externa · tocar para cargar\n${uri.host}',
              textAlign: TextAlign.center),
        ),
      );
    }
    // Decodifica la imagen al tamaño en que se muestra (máximo 1200 px)
    // para que una imagen enorme no agote la memoria.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = ((width ?? 420).clamp(1, 420) * dpr).round().clamp(1, 1200);
    final url = uri.toString();
    final path = uri.path.toLowerCase();
    final isSvg = path.endsWith('.svg') ||
        uri.host == 'img.shields.io' ||
        uri.host.endsWith('badgen.net') ||
        path.contains('/badge');
    const hidden = SizedBox.shrink();
    final Widget image = isSvg
        ? SvgPicture.network(
            url,
            width: width,
            height: height ?? (width == null ? 22 : null),
            errorBuilder: (_, _, _) => hidden,
            placeholderBuilder: (_) => hidden,
          )
        : Image.network(url,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) => hidden);
    // Capturas grandes: no más anchas que un teléfono, centradas.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
      ),
    );
  }
}

/// Pestaña Salud: puntuación de 0 a 100 con el desglose de cada criterio.
class _HealthTab extends StatelessWidget {
  const _HealthTab(this.result);
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MaxWidth(
        child: Column(
          children: [
            HealthGauge(score: result.healthScore, size: 140),
            const SizedBox(height: 8),
            Text('Puntuación de salud', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (final check in result.healthChecks)
                    ListTile(
                      leading: Icon(
                        check.passed ? Icons.check_circle : Icons.cancel,
                        color: check.passed ? AppColors.of(context).green : theme.colorScheme.error,
                      ),
                      title: Text(check.label),
                      trailing: Text(
                        check.passed ? '+${check.points}' : '0 / ${check.points}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (result.alerts.isEmpty)
              Card(
                child: ListTile(
                  leading: Icon(Icons.verified_user, color: AppColors.of(context).green),
                  title: Text('Sin alertas de seguridad'),
                  subtitle: Text('No se encontraron archivos sensibles.'),
                ),
              )
            else
              _AlertsCard(result.alerts),
            if (result.insights?.recommendations.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Qué mejorar', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 4),
              Card(
                child: Column(
                  children: [
                    for (final tip in result.insights!.recommendations)
                      ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(tip),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de estructura: tamaño del árbol y buenas prácticas detectadas.
class _StructureCard extends StatelessWidget {
  const _StructureCard(this.insights);
  final RepoInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('${insights.totalFiles} archivos'),
                Text('${insights.totalDirs} carpetas'),
                Text(Fmt.bytes(insights.totalBytes)),
                Text('Profundidad ${insights.maxDepth}'),
              ],
            ),
            if (insights.truncated)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Repositorio muy grande: GitHub mostró solo una parte del árbol.',
                    style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in insights.signals)
                  Chip(
                    avatar: Icon(
                      s.present ? Icons.check_circle : Icons.remove_circle_outline,
                      size: 18,
                      color: s.present ? AppColors.of(context).green : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(s.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de la pestaña Archivos: extensiones y archivos más pesados.
class _FilesSummary extends StatelessWidget {
  const _FilesSummary(this.insights);
  final RepoInsights insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${insights.totalFiles} archivos en ${insights.totalDirs} carpetas',
              style: theme.textTheme.titleMedium),
          if (insights.extensions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Tipos de archivo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final e in insights.extensions)
                  Chip(label: Text('${e.extension} · ${e.count}')),
              ],
            ),
          ],
          if (insights.largestFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Archivos más pesados', style: theme.textTheme.titleSmall),
            for (final f in insights.largestFiles)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(Fmt.bytes(f.size)),
              ),
          ],
          const Divider(),
          Text('Raíz del repositorio', style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
