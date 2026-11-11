import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils.dart';
import '../models/favorite.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'analyze_screen.dart';
import 'result_screen.dart';

/// Favoritos: consultar, abrir, editar la nota y eliminar.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  /// UPDATE: edita la nota del favorito.
  Future<void> _editNote(BuildContext context, Favorite favorite) async {
    final note = await askNote(context, initial: favorite.note, title: 'Editar nota');
    if (note == null || !context.mounted) return;
    final ok = await context.read<FavoritesProvider>().updateNote(favorite, note);
    if (!context.mounted) return;
    showSnack(context, ok ? 'Nota actualizada' : 'No se pudo actualizar la nota');
  }

  /// DELETE: elimina el favorito tras confirmar.
  Future<void> _remove(BuildContext context, Favorite favorite) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Eliminar favorito',
      message: '¿Eliminar ${favorite.fullName} de tus favoritos?',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await context.read<FavoritesProvider>().remove(favorite.id!);
    if (!context.mounted) return;
    showSnack(context, ok ? 'Favorito eliminado' : 'No se pudo eliminar el favorito');
  }

  /// Vuelve a analizar el repo y abre su informe.
  Future<void> _open(BuildContext context, Favorite favorite) async {
    final analysis = context.read<AnalysisProvider>();
    final messenger = ScaffoldMessenger.of(context);
    // Mientras carga, la barra superior muestra un indicador de progreso.
    final ok = await runAnalysis(context, favorite.fullName);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(analysis.error?.message ?? 'No se pudo analizar el repositorio'),
        action: SnackBarAction(
          label: 'Reintentar',
          onPressed: () {
            if (context.mounted) _open(context, favorite);
          },
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final opening = context.watch<AnalysisProvider>().status == AnalysisStatus.loading;

    Widget body;
    if (favorites.loading) {
      body = const LoadingView(message: 'Cargando favoritos...');
    } else if (favorites.error != null) {
      body = ErrorView(
        error: favorites.error!,
        onRetry: () {
          if (userId != null) favorites.load(userId);
        },
      );
    } else if (favorites.items.isEmpty) {
      body = const EmptyState(
        icon: Icons.star_outline,
        title: 'Sin favoritos',
        message: 'Toca la estrella en un informe para guardar el repositorio aquí.',
      );
    } else {
      body = MaxWidth(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: favorites.items.length,
          itemBuilder: (context, i) {
            final favorite = favorites.items[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Color(0xFFFFAB00)),
                title: Text(favorite.fullName),
                subtitle: Text(
                  favorite.note.isEmpty
                      ? 'Sin nota · ${Fmt.date(favorite.updatedAt)}'
                      : '${favorite.note}\nActualizado: ${Fmt.date(favorite.updatedAt)}',
                ),
                isThreeLine: favorite.note.isNotEmpty,
                onTap: opening ? null : () => _open(context, favorite),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Editar nota de ${favorite.fullName}',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar nota',
                        onPressed: () => _editNote(context, favorite),
                      ),
                    ),
                    Semantics(
                      label: 'Eliminar ${favorite.fullName} de favoritos',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar',
                        onPressed: () => _remove(context, favorite),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        bottom: opening
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: body,
    );
  }
}
