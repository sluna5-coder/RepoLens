import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/constants.dart';
import 'package:repolens/core/exceptions.dart';
import 'package:repolens/models/user.dart';
import 'package:repolens/services/auth_service.dart';
import 'package:repolens/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fakes.dart';

/// Iteraciones reducidas para que las pruebas sean rápidas; el formato y el
/// algoritmo son los mismos que en producción.
const _testIterations = 1000;

void main() {
  group('Hash de contraseña', () {
    test('PBKDF2-HMAC-SHA256 coincide con los vectores de prueba conocidos', () {
      // Vectores públicos de PBKDF2-HMAC-SHA256 ("password", "salt", 32 bytes).
      expect(AuthService.pbkdf2('password', 'salt', 1),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
      expect(AuthService.pbkdf2('password', 'salt', 2),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
    });

    test('el hash lleva el prefijo de formato y se verifica', () {
      final h = AuthService.hashPassword('Demo1234', 's1', iterations: _testIterations);
      expect(h, startsWith('pbkdf2\$$_testIterations\$'));
      expect(h.split(r'$').last, hasLength(64));
      expect(h, isNot(contains('Demo1234')));
      expect(AuthService.verifyPassword('Demo1234', 's1', h), isTrue);
      expect(AuthService.verifyPassword('Demo1235', 's1', h), isFalse);
      expect(AuthService.needsRehash(h), isFalse);
    });

    test('el hash cambia con otro salt', () {
      final h1 = AuthService.hashPassword('Demo1234', 'salt-uno', iterations: _testIterations);
      final h2 = AuthService.hashPassword('Demo1234', 'salt-dos', iterations: _testIterations);
      expect(h1, isNot(h2));
      expect(AuthService.generateSalt(), isNot(AuthService.generateSalt()));
    });

    test('el hash antiguo SHA-256 se sigue verificando', () {
      // sha256("abc") es un vector de prueba estándar: salt "a" + contraseña "bc".
      const legacy = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
      expect(AuthService.legacyHash('bc', 'a'), legacy);
      expect(AuthService.verifyPassword('bc', 'a', legacy), isTrue);
      expect(AuthService.verifyPassword('bd', 'a', legacy), isFalse);
      expect(AuthService.needsRehash(legacy), isTrue);
    });
  });

  group('AuthService', () {
    late FakeUserRepository repo;
    late AuthService auth;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = FakeUserRepository();
      now = DateTime(2026, 11, 12, 10);
      auth = AuthService(repo, iterations: _testIterations, clock: () => now);
    });

    test('registra, guarda el hash (no la contraseña) e inicia sesión', () async {
      final user = await auth.register(name: 'Saúl', email: 'Saul@Correo.com', password: 'Clave1234');
      expect(user.email, 'saul@correo.com');
      expect(user.passwordHash, isNot(contains('Clave1234')));
      expect(user.passwordHash, startsWith('pbkdf2\$'));
      expect(AuthService.verifyPassword('Clave1234', user.salt, user.passwordHash), isTrue);

      final logged = await auth.login('saul@correo.com', 'Clave1234');
      expect(logged.id, user.id);
      expect((await auth.currentUser())?.email, 'saul@correo.com'); // sesión persistida
    });

    test('migra un hash antiguo SHA-256 a PBKDF2 al iniciar sesión', () async {
      final id = await repo.insert(User(
        name: 'Antiguo',
        email: 'viejo@correo.com',
        passwordHash: AuthService.legacyHash('Clave1234', 'salt-v1'),
        salt: 'salt-v1',
        createdAt: DateTime(2026, 1, 1),
      ));
      await auth.login('viejo@correo.com', 'Clave1234');
      final migrated = (await repo.findById(id))!.passwordHash;
      expect(migrated, startsWith('pbkdf2\$'));
      expect(AuthService.verifyPassword('Clave1234', 'salt-v1', migrated), isTrue);
      // La cuenta sigue entrando con la misma contraseña después de migrar.
      await auth.logout();
      expect((await auth.login('viejo@correo.com', 'Clave1234')).id, id);
    });

    test('con muchas iteraciones el hash se calcula en otro isolate (compute)', () async {
      final heavy = AuthService(repo, iterations: 10000);
      final user = await heavy.register(name: 'B', email: 'b@correo.com', password: 'Clave1234');
      expect(user.passwordHash, startsWith('pbkdf2\$10000\$'));
      expect((await heavy.login('b@correo.com', 'Clave1234')).id, user.id);
      await expectLater(heavy.login('b@correo.com', 'Otra12345'), throwsA(isA<AuthException>()));
    });

    test('no permite emails duplicados', () async {
      await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      expect(
        auth.register(name: 'B', email: 'A@correo.com', password: 'Otra12345'),
        throwsA(isA<AuthException>()),
      );
    });

    test('contraseña incorrecta o usuario inexistente lanza AuthException', () async {
      await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      await expectLater(auth.login('a@correo.com', 'Incorrecta1'), throwsA(isA<AuthException>()));
      now = now.add(const Duration(seconds: 2));
      await expectLater(auth.login('nadie@correo.com', 'Clave1234'), throwsA(isA<AuthException>()));
    });

    test('tras cada fallo la espera crece (1 s, 2 s, 4 s) y un acierto la reinicia', () async {
      await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      Future<void> fail() => expectLater(
          auth.login('a@correo.com', 'Incorrecta1'),
          throwsA(isA<AuthException>()
              .having((e) => e.message, 'message', 'Email o contraseña incorrectos')));
      Matcher blocked(int s) => throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', contains('Espera $s s')));

      await fail();
      // Ni siquiera la contraseña correcta entra durante la espera.
      await expectLater(auth.login('a@correo.com', 'Clave1234'), blocked(1));
      now = now.add(const Duration(seconds: 1));
      await fail();
      await expectLater(auth.login('a@correo.com', 'Clave1234'), blocked(2));
      now = now.add(const Duration(seconds: 2));
      await fail();
      await expectLater(auth.login('a@correo.com', 'Clave1234'), blocked(4));
      now = now.add(const Duration(seconds: 4));
      expect((await auth.login('a@correo.com', 'Clave1234')).email, 'a@correo.com');
      // Tras el acierto, un nuevo fallo vuelve a 1 s.
      await fail();
      await expectLater(auth.login('a@correo.com', 'Clave1234'), blocked(1));
    });

    test('crea el usuario demo una sola vez y cerrar sesión borra la sesión', () async {
      await auth.ensureDemoUser();
      await auth.ensureDemoUser(); // no debe fallar por duplicado
      await auth.login(AppConstants.demoEmail, AppConstants.demoPassword);
      expect(await auth.currentUser(), isNotNull);
      await auth.logout();
      expect(await auth.currentUser(), isNull);
      expect(repo.sessions, isEmpty); // también se borra de la BD
    });
  });

  group('Sesión por token', () {
    late FakeUserRepository repo;
    late AuthService auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = FakeUserRepository();
      auth = AuthService(repo, iterations: _testIterations);
    });

    test('guarda un token aleatorio en el dispositivo y solo su hash en la BD', () async {
      final user = await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      await auth.login('a@correo.com', 'Clave1234');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.prefSessionToken)!;
      expect(token.length, greaterThanOrEqualTo(43)); // 32 bytes en base64
      expect(prefs.containsKey(AppConstants.prefLegacySessionUserId), isFalse);
      expect(repo.sessions.keys, [AuthService.sessionHash(token)]);
      expect(repo.sessions.keys.first, isNot(token));
      expect((await auth.currentUser())?.id, user.id);
    });

    test('un token alterado o el id antiguo en prefs no abren sesión', () async {
      final user = await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      await auth.login('a@correo.com', 'Clave1234');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefSessionToken, 'token-inventado');
      expect(await auth.currentUser(), isNull);

      // Formato de la versión 1: solo el id del usuario. Ya no vale y se borra.
      await prefs.remove(AppConstants.prefSessionToken);
      await prefs.setInt(AppConstants.prefLegacySessionUserId, user.id!);
      expect(await auth.currentUser(), isNull);
      expect(prefs.containsKey(AppConstants.prefLegacySessionUserId), isFalse);
    });

    test('iniciar sesión otra vez invalida la sesión anterior del dispositivo', () async {
      await auth.register(name: 'A', email: 'a@correo.com', password: 'Clave1234');
      await auth.login('a@correo.com', 'Clave1234');
      await auth.login('a@correo.com', 'Clave1234');
      expect(repo.sessions, hasLength(1));
    });
  });

  group('Token de GitHub por usuario', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('cada cuenta lee solo su propio token', () async {
      final tokens = TokenService();
      await tokens.save(1, ' ghp_uno ');
      await tokens.save(2, 'ghp_dos');
      expect(await tokens.read(1), 'ghp_uno');
      expect(await tokens.read(2), 'ghp_dos');
      expect(await tokens.read(3), isNull);
      await tokens.delete(1);
      expect(await tokens.read(1), isNull);
      expect(await tokens.read(2), 'ghp_dos');
    });

    test('el token global antiguo se borra y no se asigna a nadie', () async {
      FlutterSecureStorage.setMockInitialValues({AppConstants.legacySecureTokenKey: 'ghp_viejo'});
      final tokens = TokenService();
      await tokens.deleteLegacy();
      expect(await const FlutterSecureStorage().read(key: AppConstants.legacySecureTokenKey), isNull);
      expect(await tokens.read(1), isNull);
    });
  });
}
