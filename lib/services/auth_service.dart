import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../data/user_repository.dart';
import '../models/user.dart';

/// Autenticación 100 % local: usuarios en SQLite, contraseña con
/// PBKDF2-HMAC-SHA256 + salt y sesión con un token aleatorio cuyo hash se
/// guarda en SQLite (tabla `sessions`).
class AuthService {
  AuthService(
    this._users, {
    this.iterations = AppConstants.pbkdf2Iterations,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final UserRepository _users;

  /// Iteraciones de PBKDF2 para hashes nuevos. Las pruebas usan menos.
  final int iterations;
  final DateTime Function() _now;

  /// Prefijo del formato actual: `pbkdf2$<iteraciones>$<hex>`.
  static const String _pbkdf2Prefix = 'pbkdf2';

  /// Intentos fallidos seguidos y hasta cuándo se rechaza un nuevo intento
  /// (en memoria: se reinicia al cerrar la app).
  int _failures = 0;
  DateTime? _blockedUntil;

  /// Genera un salt aleatorio de 16 bytes (codificado en base64).
  static String generateSalt() => _randomToken(16);

  static String _randomToken(int bytes) {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(bytes, (_) => random.nextInt(256)));
  }

  /// Hash antiguo (v1): SHA-256 de `salt + contraseña`, en hexadecimal.
  /// Solo se usa para verificar cuentas creadas antes de PBKDF2.
  static String legacyHash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// PBKDF2-HMAC-SHA256 (RFC 8018) con una salida de 32 bytes, en hexadecimal.
  static String pbkdf2(String password, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    // Un solo bloque: 32 bytes es justo el tamaño de SHA-256.
    var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hash en el formato actual: `pbkdf2$<iteraciones>$<hex>`.
  static String hashPassword(String password, String salt,
          {int iterations = AppConstants.pbkdf2Iterations}) =>
      '$_pbkdf2Prefix\$$iterations\$${pbkdf2(password, salt, iterations)}';

  /// Comprueba una contraseña contra un hash guardado (formato actual o v1).
  static bool verifyPassword(String password, String salt, String stored) {
    final parts = stored.split(r'$');
    if (parts.length == 3 && parts[0] == _pbkdf2Prefix) {
      final rounds = int.tryParse(parts[1]);
      if (rounds == null || rounds < 1) return false;
      return _equals(pbkdf2(password, salt, rounds), parts[2]);
    }
    return _equals(legacyHash(password, salt), stored);
  }

  /// `true` si el hash guardado es del formato antiguo y hay que rehacerlo.
  static bool needsRehash(String stored) => !stored.startsWith('$_pbkdf2Prefix\$');

  /// Comparación en tiempo constante.
  static bool _equals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Calcula el hash fuera del hilo de la interfaz en móvil (en web `compute`
  /// corre en el mismo hilo, así que se llama directo).
  Future<String> _hash(String password, String salt) {
    if (kIsWeb || iterations < 10000) {
      return Future.value(hashPassword(password, salt, iterations: iterations));
    }
    return compute(_hashJob, (password, salt, iterations));
  }

  Future<bool> _verify(String password, String salt, String stored) {
    if (kIsWeb || iterations < 10000) {
      return Future.value(verifyPassword(password, salt, stored));
    }
    return compute(_verifyJob, (password, salt, stored));
  }

  // Funciones estáticas para `compute` (no capturan el servicio).
  static String _hashJob((String, String, int) a) =>
      hashPassword(a.$1, a.$2, iterations: a.$3);
  static bool _verifyJob((String, String, String) a) => verifyPassword(a.$1, a.$2, a.$3);

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
      passwordHash: await _hash(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    final id = await _users.insert(user);
    return user.copyWith(id: id);
  }

  /// Inicia sesión: vuelve a calcular el hash con el salt guardado y lo compara.
  /// Tras cada fallo hay que esperar más antes de reintentar (1 s, 2 s, 4 s...
  /// hasta 30 s). No se bloquea la interfaz: el intento se rechaza con aviso.
  Future<User> login(String email, String password) async {
    final blockedUntil = _blockedUntil;
    final now = _now();
    if (blockedUntil != null && now.isBefore(blockedUntil)) {
      final seconds = (blockedUntil.difference(now).inMilliseconds / 1000).ceil();
      throw AuthException('Demasiados intentos fallidos. Espera $seconds s e inténtalo de nuevo.');
    }
    final user = await _users.findByEmail(email.trim().toLowerCase());
    if (user == null || !await _verify(password, user.salt, user.passwordHash)) {
      _failures++;
      final delay = min(30, 1 << min(_failures - 1, 5));
      _blockedUntil = _now().add(Duration(seconds: delay));
      throw const AuthException('Email o contraseña incorrectos');
    }
    _failures = 0;
    _blockedUntil = null;
    // Cuenta con el hash antiguo: se migra a PBKDF2 ahora que se conoce la clave.
    if (needsRehash(user.passwordHash)) {
      await _users.updatePasswordHash(user.id!, await _hash(password, user.salt));
    }
    await _saveSession(user.id!);
    return user;
  }

  /// Crea el usuario de prueba si no existe. Solo se llama en depuración.
  Future<void> ensureDemoUser() async {
    if (await _users.findByEmail(AppConstants.demoEmail) != null) return;
    await register(
      name: AppConstants.demoName,
      email: AppConstants.demoEmail,
      password: AppConstants.demoPassword,
    );
  }

  /// Hash SHA-256 del token de sesión: es lo único que se guarda en SQLite.
  static String sessionHash(String token) => sha256.convert(utf8.encode(token)).toString();

  /// Recupera al usuario de la sesión guardada (o `null` si no hay).
  Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Sesiones de la versión 1 (solo el id): se descartan.
    if (prefs.containsKey(AppConstants.prefLegacySessionUserId)) {
      await prefs.remove(AppConstants.prefLegacySessionUserId);
    }
    final token = prefs.getString(AppConstants.prefSessionToken);
    if (token == null || token.isEmpty) return null;
    return _users.findBySessionHash(sessionHash(token));
  }

  /// Cierra la sesión: borra el token del dispositivo y su registro en SQLite.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefSessionToken);
    await prefs.remove(AppConstants.prefSessionToken);
    if (token != null) await _users.deleteSession(sessionHash(token));
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    // La sesión anterior de este dispositivo deja de valer.
    final previous = prefs.getString(AppConstants.prefSessionToken);
    if (previous != null) await _users.deleteSession(sessionHash(previous));
    final token = _randomToken(32);
    await _users.createSession(userId, sessionHash(token));
    await prefs.setString(AppConstants.prefSessionToken, token);
  }
}
