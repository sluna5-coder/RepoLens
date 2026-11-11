import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/analysis_result.dart';
import '../models/history_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Abre un informe guardado en el historial a partir de su snapshot JSON.
void openHistoryEntry(BuildContext context, HistoryEntry entry) {
  try {
    final result = AnalysisResult.fromJson(
        jsonDecode(entry.jsonSnapshot) as Map<String, dynamic>);
    Navigator.pushNamed(context, AppRoutes.result, arguments: result);
  } catch (_) {
    showSnack(context, 'No se pudo abrir el informe guardado');
  }
}

/// Pantalla de inicio: presenta el proyecto y da acceso a las funciones
/// principales y a los últimos análisis.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Cambia de pestaña en el contenedor principal (0 a 4).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final recent = context.watch<HistoryProvider>().entries.take(3).toList();

    final actions = [
      (Icons.search, 'Analizar repo', 'Pega una URL y obtén el informe', () => onNavigate(1)),
      (
        Icons.compare_arrows,
        'Comparar',
        'Dos repos lado a lado',
        () => Navigator.pushNamed(context, AppRoutes.compare),
      ),
      (Icons.history, 'Historial', 'Tus análisis anteriores', () => onNavigate(2)),
      (Icons.star, 'Favoritos', 'Repos guardados con notas', () => onNavigate(3)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidth(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const AppLogo(size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hola, ${user?.name ?? ''}',
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            const Text(
                              'RepoLens analiza cualquier repositorio público de GitHub: '
                              'datos clave, lenguajes, commits, salud y alertas de seguridad.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Funciones', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              // LayoutBuilder: 2 columnas en teléfono, 4 en tableta.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.15,
                    children: [
                      for (final (icon, title, subtitle, onTap) in actions)
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onTap,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, size: 32, color: theme.colorScheme.primary),
                                  const Spacer(),
                                  Text(title, style: theme.textTheme.titleMedium),
                                  Text(subtitle,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Análisis recientes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.inbox_outlined),
                    title: Text('Aún no has analizado ningún repositorio'),
                    subtitle: Text('Empieza desde la pestaña Analizar'),
                  ),
                )
              else
                for (final entry in recent)
                  Card(
                    child: ListTile(
                      leading: HealthBadge(score: entry.healthScore),
                      title: Text(entry.fullName),
                      subtitle: Text(Fmt.dateTime(entry.analyzedAt)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openHistoryEntry(context, entry),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
