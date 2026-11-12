import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Tema elegido por el usuario (sistema, claro u oscuro), persistido
/// en shared_preferences. Por defecto es oscuro.
class ThemeProvider extends ChangeNotifier {
  ThemeMode mode = ThemeMode.dark;

  /// Lee la preferencia guardada al iniciar la app.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefThemeMode);
    mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
    notifyListeners();
  }

  /// `true` si se está mostrando el tema oscuro.
  bool isDark(BuildContext context) =>
      mode == ThemeMode.dark ||
      (mode == ThemeMode.system &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  /// Alterna entre claro y oscuro (botón de sol y luna).
  Future<void> toggle(BuildContext context) =>
      setMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);

  /// Cambia el tema y lo guarda.
  Future<void> setMode(ThemeMode newMode) async {
    mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, newMode.name);
  }
}
