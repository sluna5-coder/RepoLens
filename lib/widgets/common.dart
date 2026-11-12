import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/theme_provider.dart';

/// Color según la puntuación de salud: verde, naranja o rojo.
Color healthColor(int score) {
  if (score >= 70) return AppColors.dark.green;
  if (score >= 40) return AppColors.dark.orange;
  return AppColors.dark.red;
}

/// Indicador circular con la puntuación de salud al centro.
class HealthGauge extends StatelessWidget {
  const HealthGauge({super.key, required this.score, this.size = 120});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = healthColor(score);
    return Semantics(
      label: 'Puntuación de salud: $score de 100',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size / 12,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.18),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: size / 3.4,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  Text('de 100',
                      style: TextStyle(
                          fontSize: size / 11, color: AppColors.of(context).secondaryLabel)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastilla pequeña con la puntuación (para listas).
class HealthBadge extends StatelessWidget {
  const HealthBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: healthColor(score).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: TextStyle(color: healthColor(score), fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Tarjeta con un dato numérico (estrellas, forks...).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Limita el ancho del contenido en pantallas grandes (tabletas) para que
/// los formularios y listas no se estiren de lado a lado.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Logo de la app: una lupa sobre fondo del color primario.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5AC8FA), Color(0xFF0A84FF), Color(0xFF5E5CE6)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2237),
      ),
      child: Icon(Icons.travel_explore, size: size * 0.56, color: Colors.white),
    );
  }
}

/// Icono blanco dentro de un cuadro redondeado de color, como en los
/// ajustes del teléfono.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 30});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
  }
}

/// Sección agrupada: título pequeño arriba y una tarjeta con las filas
/// separadas por líneas finas.
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                  color: colors.secondaryLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 16),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(footer!,
                  style: TextStyle(fontSize: 12.5, color: colors.secondaryLabel)),
            ),
        ],
      ),
    );
  }
}

/// Botón de sol y luna que alterna entre el tema claro y el oscuro.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final dark = theme.isDark(context);
    return IconButton(
      key: const Key('theme_toggle'),
      tooltip: dark ? 'Usar tema claro' : 'Usar tema oscuro',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => theme.toggle(context),
    );
  }
}
