import 'package:flutter/material.dart';

/// Temas claro y oscuro (Material 3) con una paleta consistente
/// generada a partir de un color semilla.
class AppTheme {
  static const Color seed = Color(0xFF3D5AFE);

  /// Colores para la gráfica de lenguajes.
  static const List<Color> chartColors = [
    Color(0xFF3D5AFE),
    Color(0xFF00BFA5),
    Color(0xFFFFAB00),
    Color(0xFFFF5252),
    Color(0xFF7C4DFF),
    Color(0xFF00B8D4),
    Color(0xFF64DD17),
    Color(0xFFFF6E40),
  ];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
