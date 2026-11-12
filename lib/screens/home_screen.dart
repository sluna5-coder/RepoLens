import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/theme.dart';
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
    final colors = AppColors.of(context);
    final user = context.watch<AuthProvider>().user;
    final recent = context.watch<HistoryProvider>().entries.take(3).toList();
    final firstName = (user?.name ?? '').split(' ').first;

    final actions = [
      (Icons.search, colors.accent, 'Analizar repo', 'Pega una URL y obtén el informe',
          () => onNavigate(1)),
      (
        Icons.compare_arrows,
        const Color(0xFF5E5CE6),
        'Comparar',
        'Dos repos lado a lado',
        () => Navigator.pushNamed(context, AppRoutes.compare),
      ),
      (Icons.history, colors.orange, 'Historial', 'Tus análisis anteriores',
          () => onNavigate(2)),
      (Icons.star, const Color(0xFFFFCC00), 'Favoritos', 'Repos guardados con notas',
          () => onNavigate(3)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: const [ThemeToggleButton(), SizedBox(width: 4)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: MaxWidth(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? 'Hola' : 'Hola, $firstName',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Analiza cualquier repositorio público de GitHub: datos clave, '
                'lenguajes, commits, salud y alertas de seguridad.',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.secondaryLabel),
              ),
              const SizedBox(height: 24),
              // LayoutBuilder: 2 columnas en teléfono, 4 en tableta.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 4 : 2;
                  return GridView(
                    // Alto fijo por tarjeta: evita desbordes con textos grandes.
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 148,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final (icon, color, title, subtitle, onTap) in actions)
                        Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: onTap,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconBadge(icon: icon, color: color, size: 36),
                                  const SizedBox(height: 18),
                                  Text(title,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Expanded(
                                    child: Text(subtitle,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              GroupedSection(
                title: 'Análisis recientes',
                children: [
                  if (recent.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.inbox_outlined),
                      title: Text('Aún no has analizado ningún repositorio'),
                      subtitle: Text('Empieza desde la pestaña Analizar'),
                    )
                  else
                    for (final entry in recent)
                      ListTile(
                        leading: HealthBadge(score: entry.healthScore),
                        title: Text(entry.fullName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(Fmt.dateTime(entry.analyzedAt)),
                        trailing: Icon(Icons.chevron_right, color: colors.secondaryLabel),
                        onTap: () => openHistoryEntry(context, entry),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
