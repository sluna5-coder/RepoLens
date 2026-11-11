import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Estado de autenticación: usuario actual, carga y último error.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  User? user;
  bool loading = false;

  /// Mensaje del último error (credenciales incorrectas, email duplicado...).
  String? error;

  bool get isLoggedIn => user != null;

  /// Se llama desde el Splash: crea el usuario demo y restaura la sesión.
  Future<void> init() async {
    try {
      await _service.ensureDemoUser();
      user = await _service.currentUser();
    } on AppException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  /// Devuelve `true` si las credenciales son correctas.
  Future<bool> login(String email, String password) =>
      _run(() async => user = await _service.login(email, password));

  /// Registra y deja la sesión iniciada. `false` si el email ya existe.
  Future<bool> register(String name, String email, String password) => _run(() async {
        await _service.register(name: name, email: email, password: password);
        user = await _service.login(email, password);
      });

  Future<void> logout() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }

  /// Envuelve una operación: activa `loading`, guarda el error y notifica.
  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
