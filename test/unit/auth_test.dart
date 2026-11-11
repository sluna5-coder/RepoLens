import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/constants.dart';
import 'package:repolens/core/exceptions.dart';
import 'package:repolens/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fakes.dart';

void main() {
  group('Hash de contraseña', () {
    test('SHA-256 con salt es determinista y coincide con el valor conocido', () {
      // sha256("abc") es un vector de prueba estándar: salt "a" + contraseña "bc".
      expect(
        AuthService.hashPassword('bc', 'a'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(AuthService.hashPassword('Demo1234', 's1'), AuthService.hashPassword('Demo1234', 's1'));
    });

    test('el hash cambia con otro salt y nunca contiene la contraseña', () {
      final h1 = AuthService.hashPassword('Demo1234', 'salt-uno');
      final h2 = AuthService.hashPassword('Demo1234', 'salt-dos');
      expect(h1, isNot(h2));
      expect(h1, hasLength(64));
      expect(h1, isNot(contains('Demo1234')));
      expect(AuthService.generateSalt(), isNot(AuthService.generateSalt()));
    });
  });

  group('AuthService', () {
    late AuthService auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      auth = AuthService(FakeUserRepository());
    });

    test('registra, guarda el hash (no la contraseña) e inicia sesión', () async {
      final user = await auth.register(name: 'Saúl', email: 'Saul@Correo.com', password: 'Clave1234');
      expect(user.email, 'saul@correo.com');
      expect(user.passwordHash, isNot('Clave1234'));
      expect(user.passwordHash, AuthService.hashPassword('Clave1234', user.salt));

      final logged = await auth.login('saul@correo.com', 'Clave1234');
      expect(logged.id, user.id);
      expect((await auth.currentUser())?.email, 'saul@correo.com'); // sesión persistida
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
      expect(auth.login('a@correo.com', 'Incorrecta1'), throwsA(isA<AuthException>()));
      expect(auth.login('nadie@correo.com', 'Clave1234'), throwsA(isA<AuthException>()));
    });

    test('crea el usuario demo una sola vez y cerrar sesión borra la sesión', () async {
      await auth.ensureDemoUser();
      await auth.ensureDemoUser(); // no debe fallar por duplicado
      await auth.login(AppConstants.demoEmail, AppConstants.demoPassword);
      expect(await auth.currentUser(), isNotNull);
      await auth.logout();
      expect(await auth.currentUser(), isNull);
    });
  });
}
