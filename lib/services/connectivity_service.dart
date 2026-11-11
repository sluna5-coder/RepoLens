import 'package:connectivity_plus/connectivity_plus.dart';

/// Verifica si el dispositivo tiene alguna red activa (wifi, datos, etc.)
/// antes de intentar una petición.
class ConnectivityService {
  /// Devuelve `true` si hay al menos una interfaz de red conectada.
  /// Si el plugin falla se asume que sí hay red y la petición decide.
  Future<bool> hasConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }
}
