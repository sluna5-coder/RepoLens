import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

/// Guarda el token personal de GitHub (opcional) en el almacenamiento seguro
/// del dispositivo. El token nunca se escribe en el código ni en SQLite.
class TokenService {
  TokenService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Lee el token guardado; `null` si no hay o si el almacén falla.
  Future<String?> read() async {
    try {
      return await _storage.read(key: AppConstants.secureTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String token) =>
      _storage.write(key: AppConstants.secureTokenKey, value: token.trim());

  Future<void> delete() => _storage.delete(key: AppConstants.secureTokenKey);
}
