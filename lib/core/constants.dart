/// Constantes globales de la aplicación.
class AppConstants {
  static const String appName = 'RepoLens';

  /// URL base de la API REST pública de GitHub.
  static const String apiBase = 'https://api.github.com';

  /// Tiempo máximo de espera por petición HTTP.
  static const Duration timeout = Duration(seconds: 10);

  /// Vigencia de la caché local (evita rebasar 60 peticiones/hora sin token).
  static const Duration cacheTtl = Duration(minutes: 30);

  /// Longitud máxima de la nota de un favorito.
  static const int maxNoteLength = 300;

  /// Usuario de prueba creado en la primera ejecución.
  static const String demoName = 'Usuario Demo';
  static const String demoEmail = 'demo@repolens.app';
  static const String demoPassword = 'Demo1234';

  /// Claves de shared_preferences / secure storage.
  static const String prefSessionUserId = 'session_user_id';
  static const String prefThemeMode = 'theme_mode';
  static const String secureTokenKey = 'github_token';
}
