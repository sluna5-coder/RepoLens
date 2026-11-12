import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

/// Guarda el token personal de GitHub (opcional) en el almacenamiento seguro
/// del dispositivo. El token nunca se escribe en el código ni en SQLite.
///
/// Cada usuario tiene su propia clave (`github_token_<id>`): el token de una
/// cuenta nunca se usa con otra.
class TokenService {
  TokenService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Lee el token del usuario; `null` si no hay o si el almacén falla.
  Future<String?> read(int userId) async {
    try {
      return await _storage.read(key: AppConstants.secureTokenKeyFor(userId));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(int userId, String token) => _storage.write(
      key: AppConstants.secureTokenKeyFor(userId), value: token.trim());

  Future<void> delete(int userId) =>
      _storage.delete(key: AppConstants.secureTokenKeyFor(userId));

  /// Borra el token global de la versión anterior (no se asigna a nadie,
  /// porque no se sabe de qué cuenta era).
  Future<void> deleteLegacy() async {
    try {
      await _storage.delete(key: AppConstants.legacySecureTokenKey);
    } catch (_) {/* sin almacén seguro: no hay nada que borrar */}
  }
}
