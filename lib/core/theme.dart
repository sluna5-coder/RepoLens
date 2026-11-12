import 'package:flutter/material.dart';

/// Paleta inspirada en el estilo de las apps de iOS: fondos neutros,
/// superficies agrupadas, un solo color de acento y mucho aire.
/// No usa fuentes ni iconos de Apple: el parecido sale de colores,
/// espaciados y radios.
class AppColors {
  const AppColors._({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.separator,
    required this.label,
    required this.secondaryLabel,
    required this.accent,
    required this.green,
    required this.orange,
    required this.red,
  });

  /// Fondo de la pantalla.
  final Color background;

  /// Tarjetas y listas agrupadas.
  final Color surface;

  /// Campos de texto, chips y elementos sobre una tarjeta.
  final Color surfaceHigh;
  final Color separator;
  final Color label;
  final Color secondaryLabel;
  final Color accent;
  final Color green;
  final Color orange;
  final Color red;

  static const dark = AppColors._(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceHigh: Color(0xFF2C2C2E),
    separator: Color(0xFF38383A),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0xFF8E8E93),
    accent: Color(0xFF0A84FF),
    green: Color(0xFF30D158),
    orange: Color(0xFFFF9F0A),
    red: Color(0xFFFF453A),
  );

  static const light = AppColors._(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE9E9EE),
    separator: Color(0xFFD1D1D6),
    label: Color(0xFF000000),
    secondaryLabel: Color(0xFF6E6E73),
    accent: Color(0xFF007AFF),
    green: Color(0xFF34C759),
    orange: Color(0xFFFF9500),
    red: Color(0xFFFF3B30),
  );

  /// Paleta del tema activo.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Temas claro y oscuro de RepoLens.
class AppTheme {
  static const Color seed = Color(0xFF0A84FF);

  /// Colores para la gráfica de lenguajes.
  static const List<Color> chartColors = [
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFFF453A),
    Color(0xFFBF5AF2),
    Color(0xFF64D2FF),
    Color(0xFFFFD60A),
    Color(0xFFFF375F),
  ];

  static const double radius = 14;

  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      primaryContainer: c.accent.withValues(alpha: 0.18),
      onPrimaryContainer: c.accent,
      secondary: c.accent,
      onSecondary: Colors.white,
      secondaryContainer: c.surfaceHigh,
      onSecondaryContainer: c.label,
      tertiary: c.green,
      onTertiary: Colors.white,
      error: c.red,
      onError: Colors.white,
      errorContainer: c.red.withValues(alpha: 0.16),
      onErrorContainer: c.red,
      surface: c.surface,
      onSurface: c.label,
      onSurfaceVariant: c.secondaryLabel,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceHigh,
      surfaceContainerHighest: c.surfaceHigh,
      outline: c.separator,
      outlineVariant: c.separator,
      shadow: Colors.black,
      inverseSurface: c.label,
      onInverseSurface: c.background,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final text = base.textTheme.apply(bodyColor: c.label, displayColor: c.label).copyWith(
          headlineMedium: base.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6, color: c.label),
          headlineSmall: base.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4, color: c.label),
          titleLarge: base.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.label),
          titleMedium: base.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2, color: c.label),
          titleSmall: base.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: c.secondaryLabel),
          bodySmall: base.textTheme.bodySmall?.copyWith(color: c.secondaryLabel),
        );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      dividerColor: c.separator,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.label,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.accent),
        actionsIconTheme: IconThemeData(color: c.accent),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: shape,
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.accent,
        subtitleTextStyle: TextStyle(color: c.secondaryLabel, fontSize: 13),
        leadingAndTrailingTextStyle: TextStyle(color: c.secondaryLabel, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(color: c.separator, thickness: 0.5, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.secondaryLabel),
        labelStyle: TextStyle(color: c.secondaryLabel),
        prefixIconColor: c.secondaryLabel,
        suffixIconColor: c.secondaryLabel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          backgroundColor: c.surface,
          minimumSize: const Size(64, 50),
          side: BorderSide.none,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.accent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceHigh,
        selectedColor: c.accent.withValues(alpha: 0.2),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: c.label, fontSize: 13, fontWeight: FontWeight.w500),
        iconTheme: IconThemeData(color: c.accent, size: 16),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: c.separator, width: 0.5)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.surfaceHigh : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.label : c.secondaryLabel,
          ),
          iconColor: WidgetStatePropertyAll(c.accent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.accent : c.secondaryLabel,
            size: 26,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: s.contains(WidgetState.selected) ? c.accent : c.secondaryLabel,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: c.accent),
        unselectedIconTheme: IconThemeData(color: c.secondaryLabel),
        selectedLabelTextStyle:
            TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: c.secondaryLabel, fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.accent,
        unselectedLabelColor: c.secondaryLabel,
        indicatorColor: c.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.separator,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        tabAlignment: TabAlignment.start,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 4)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceHigh,
        contentTextStyle: TextStyle(color: c.label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
