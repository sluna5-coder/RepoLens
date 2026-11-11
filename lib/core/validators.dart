import 'constants.dart';

/// Validaciones de formularios. Cada método devuelve `null` si el valor
/// es válido, o el mensaje de error que se muestra bajo el campo.
class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  /// owner: letras, números y guion. repo: además punto y guion bajo.
  /// Grupos opcionales: protocolo, www, sufijo .git y ruta extra (/tree/...).
  static final RegExp _repoRegex = RegExp(
    r'^(?:https?://)?(?:www\.)?github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9._-]+?)(?:\.git)?(?:/.*)?$',
    caseSensitive: false,
  );

  /// Nombre obligatorio.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
    return null;
  }

  /// Email obligatorio y con formato válido.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es obligatorio';
    if (!_emailRegex.hasMatch(value.trim())) return 'Escribe un email válido';
    return null;
  }

  /// Contraseña de registro: mínimo 8 caracteres, con letra y número.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) return 'Debe incluir al menos una letra';
    if (!RegExp(r'\d').hasMatch(value)) return 'Debe incluir al menos un número';
    return null;
  }

  /// Confirmación: debe coincidir con la contraseña.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Campo obligatorio genérico (login).
  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  /// Nota de favorito: opcional, máximo 300 caracteres.
  static String? note(String? value) {
    if (value != null && value.length > AppConstants.maxNoteLength) {
      return 'La nota no puede superar ${AppConstants.maxNoteLength} caracteres';
    }
    return null;
  }

  /// URL de repositorio, para usar en un TextFormField.
  static String? repoUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pega la URL de un repositorio';
    }
    if (parseRepoUrl(value) == null) {
      return 'URL inválida. Ejemplo: https://github.com/flutter/flutter';
    }
    return null;
  }

  /// Normaliza una URL de GitHub a `owner/repo`.
  /// Acepta `https://github.com/o/r`, `github.com/o/r`, `.git` y `/tree/...`.
  /// Devuelve `null` si la URL no es válida.
  static String? parseRepoUrl(String input) {
    final match = _repoRegex.firstMatch(input.trim());
    if (match == null) return null;
    final owner = match.group(1)!;
    final repo = match.group(2)!;
    if (repo == '.' || repo == '..') return null;
    return '$owner/$repo';
  }
}
