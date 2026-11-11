import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'home_screen.dart';

/// Historial de análisis: consultar, reabrir, eliminar uno y vaciar todo.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Vaciar historial',
      message: 'Se eliminarán todos tus análisis guardados. Esta acción no se puede deshacer.',
      confirmLabel: 'Vaciar',
    );
    if (!confirmed || !context.mounted) return;
    final userId = context.read<AuthProvider>().user!.id!;
    final ok = await context.read<HistoryProvider>().clear(userId);
    if (!context.mounted) return;
    showSnack(context, ok ? 'Historial vaciado' : 'No se pudo vaciar el historial');
  }

  Future<void> _remove(BuildContext context, int id, String fullName) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Eliminar análisis',
      message: '¿Eliminar el análisis de $fullName del historial?',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await context.read<HistoryProvider>().remove(id);
    if (!context.mounted) return;
    showSnack(context, ok ? 'Análisis eliminado' : 'No se pudo eliminar el análisis');
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final userId = context.watch<AuthProvider>().user?.id;

    Widget body;
    if (history.loading) {
      body = const LoadingView(message: 'Cargando historial...');
    } else if (history.error != null) {
      body = ErrorView(
        error: history.error!,
        onRetry: () {
          if (userId != null) history.load(userId);
        },
      );
    } else if (history.entries.isEmpty) {
      body = const EmptyState(
        icon: Icons.history,
        title: 'Historial vacío',
        message: 'Cada repositorio que analices se guardará aquí.',
      );
    } else {
      body = MaxWidth(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: history.entries.length,
          itemBuilder: (context, i) {
            final entry = history.entries[i];
            return Card(
              child: ListTile(
                leading: HealthBadge(score: entry.healthScore),
                title: Text(entry.fullName),
                subtitle: Text(Fmt.dateTime(entry.analyzedAt)),
                onTap: () => openHistoryEntry(context, entry),
                trailing: Semantics(
                  label: 'Eliminar análisis de ${entry.fullName}',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                    onPressed: () => _remove(context, entry.id!, entry.fullName),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          if (history.entries.isNotEmpty)
            Semantics(
              label: 'Vaciar historial',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Vaciar historial',
                onPressed: () => _clearAll(context),
              ),
            ),
        ],
      ),
      body: body,
    );
  }
}
