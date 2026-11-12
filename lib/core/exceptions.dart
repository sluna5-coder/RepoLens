/// Excepciones tipadas de la app. Cada una trae un mensaje amable
/// listo para mostrarse al usuario (ver widgets/error_view.dart).
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Mensaje en español para el usuario.
  final String message;

  @override
  String toString() => message;
}

/// No hay conexión a internet (SocketException o connectivity_plus).
class NoConnectionException extends AppException {
  const NoConnectionException()
      : super('Sin conexión a internet. Revisa tu red e inténtalo de nuevo.');
}

/// La petición tardó más de 10 segundos.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException()
      : super('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
}

/// HTTP 404: el repositorio no existe o es privado.
class NotFoundException extends AppException {
  const NotFoundException()
      : super('No se encontró el repositorio. Puede que no exista o sea privado.');
}

/// HTTP 403/429: se agotó el límite de peticiones de la API.
class RateLimitException extends AppException {
  RateLimitException({this.resetAt})
      : super(resetAt == null
            ? 'Se alcanzó el límite de peticiones de GitHub. Inténtalo más tarde '
                'o agrega un token en Perfil.'
            : 'Se alcanzó el límite de peticiones de GitHub. Se reinicia a las '
                '${_hhmm(resetAt)}. Puedes agregar un token en Perfil.');

  /// Hora de reinicio leída del encabezado X-RateLimit-Reset.
  final DateTime? resetAt;

  static String _hhmm(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

/// HTTP 409 al pedir commits: el repositorio está vacío.
class EmptyRepoException extends AppException {
  const EmptyRepoException()
      : super('El repositorio está vacío: todavía no tiene commits que analizar.');
}

/// La respuesta no tiene el formato JSON esperado.
class UnexpectedJsonException extends AppException {
  const UnexpectedJsonException()
      : super('GitHub devolvió una respuesta inesperada. Inténtalo de nuevo.');
}

/// Cualquier otro código HTTP no contemplado.
class ApiException extends AppException {
  const ApiException(this.statusCode)
      : super('Error del servidor de GitHub (código $statusCode).');
  final int statusCode;
}

/// Falla al leer o escribir en SQLite.
class DatabaseAppException extends AppException {
  const DatabaseAppException()
      : super('Ocurrió un error con la base de datos local. Inténtalo de nuevo.');
}

/// Errores de autenticación (credenciales incorrectas, email duplicado).
class AuthException extends AppException {
  const AuthException(super.message);
}

/// La URL escrita no corresponde a un repositorio de GitHub.
class InvalidUrlException extends AppException {
  const InvalidUrlException()
      : super('URL inválida. Usa el formato https://github.com/owner/repo');
}

/// La respuesta de la API supera el tamaño máximo aceptado (10 MB).
class ResponseTooLargeException extends AppException {
  const ResponseTooLargeException()
      : super('La respuesta de GitHub es demasiado grande para procesarla (más de 10 MB).');
}
