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

  /// Usuario de prueba que pide el enunciado. Es una cuenta compartida: el
  /// token de GitHub es por usuario y los repos privados no se guardan en la
  /// caché, así que quien la use no ve datos de otras cuentas.
  static const String demoName = 'Usuario Demo';
  static const String demoEmail = 'demo@repolens.app';
  static const String demoPassword = 'Demo1234';

  /// Claves de shared_preferences / secure storage.
  /// `session_user_id` es la clave antigua (v1), solo se usa para borrarla.
  static const String prefLegacySessionUserId = 'session_user_id';
  static const String prefSessionToken = 'session_token';
  static const String prefThemeMode = 'theme_mode';

  /// Clave antigua del token, compartida por todos los usuarios. Ya no se usa:
  /// si existe se borra.
  static const String legacySecureTokenKey = 'github_token';

  /// Clave del token de GitHub de un usuario concreto.
  static String secureTokenKeyFor(int userId) => 'github_token_$userId';

  /// Iteraciones de PBKDF2-HMAC-SHA256 para las contraseñas nuevas.
  static const int pbkdf2Iterations = 100000;

  /// Tamaño máximo aceptado de una respuesta de la API (10 MB).
  static const int maxResponseBytes = 10 * 1024 * 1024;

  /// Tamaño máximo del README que se formatea y muestra (200 KB).
  static const int maxReadmeChars = 200 * 1024;
}
