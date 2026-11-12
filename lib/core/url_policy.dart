/// Reglas para el contenido externo de un README (imágenes y enlaces).
/// Es lógica pura, sin Flutter, para poder probarla.
class UrlPolicy {
  /// Hosts cuyas imágenes se cargan solas. Cualquier otro host podría
  /// registrar la IP del usuario o servir imágenes enormes.
  static const Set<String> _trustedImageHosts = {
    'raw.githubusercontent.com',
    'github.com',
    'img.shields.io',
    'badgen.net',
  };

  /// `true` si la imagen se puede cargar sin preguntar: HTTPS y un host de
  /// GitHub (incluidos los subdominios de githubusercontent.com) o de insignias.
  static bool isTrustedImage(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return _trustedImageHosts.contains(host) || host.endsWith('.githubusercontent.com');
  }

  /// `true` si el enlace lleva a GitHub (github.com, *.github.com o
  /// *.github.io) y se puede abrir sin confirmar.
  static bool isGithubLink(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'github.com' || host.endsWith('.github.com') || host.endsWith('.github.io');
  }
}
