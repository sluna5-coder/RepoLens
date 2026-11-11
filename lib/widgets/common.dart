import 'package:flutter/material.dart';

/// Color según la puntuación de salud: verde, ámbar o rojo.
Color healthColor(int score) {
  if (score >= 70) return const Color(0xFF2E7D32);
  if (score >= 40) return const Color(0xFFF9A825);
  return const Color(0xFFC62828);
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
              strokeWidth: size / 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
            Center(
              child: Text(
                '$score',
                style: TextStyle(fontSize: size / 3.2, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: healthColor(score),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$score',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(Icons.travel_explore, size: size * 0.6, color: scheme.onPrimary),
    );
  }
}
