import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../data/user_repository.dart';
import '../models/user.dart';

/// Autenticación 100 % local: usuarios en SQLite, contraseña con SHA-256 + salt
/// y sesión persistida con shared_preferences.
class AuthService {
  AuthService(this._users);

  final UserRepository _users;

  /// Genera un salt aleatorio de 16 bytes (codificado en base64).
  static String generateSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  /// Hash SHA-256 de `salt + contraseña`, en hexadecimal.
  /// El salt hace que dos usuarios con la misma contraseña tengan hash distinto.
  static String hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// Registra un usuario nuevo. Lanza [AuthException] si el email ya existe.
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (await _users.findByEmail(normalized) != null) {
      throw const AuthException('Ya existe una cuenta con ese email');
    }
    final salt = generateSalt();
    final user = User(
      name: name.trim(),
      email: normalized,
      passwordHash: hashPassword(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    final id = await _users.insert(user);
    return user.copyWith(id: id);
  }

  /// Inicia sesión: vuelve a calcular el hash con el salt guardado y lo compara.
  Future<User> login(String email, String password) async {
    final user = await _users.findByEmail(email.trim().toLowerCase());
    if (user == null || hashPassword(password, user.salt) != user.passwordHash) {
      throw const AuthException('Email o contraseña incorrectos');
    }
    await _saveSession(user.id!);
    return user;
  }

  /// Crea el usuario de prueba la primera vez que se abre la app.
  Future<void> ensureDemoUser() async {
    if (await _users.findByEmail(AppConstants.demoEmail) != null) return;
    await register(
      name: AppConstants.demoName,
      email: AppConstants.demoEmail,
      password: AppConstants.demoPassword,
    );
  }

  /// Recupera al usuario de la sesión guardada (o `null` si no hay).
  Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppConstants.prefSessionUserId);
    if (id == null) return null;
    return _users.findById(id);
  }

  /// Cierra la sesión borrando el id guardado.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSessionUserId);
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefSessionUserId, userId);
  }
}
