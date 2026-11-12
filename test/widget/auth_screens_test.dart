import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:repolens/app.dart';
import 'package:repolens/core/constants.dart';
import 'package:repolens/providers/auth_provider.dart';
import 'package:repolens/providers/theme_provider.dart';
import 'package:repolens/screens/login_screen.dart';
import 'package:repolens/screens/register_screen.dart';
import 'package:repolens/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fakes.dart';

/// Monta una pantalla con un AuthProvider respaldado por el repositorio falso.
Future<AuthService> _pump(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final service = AuthService(FakeUserRepository());
  await service.ensureDemoUser();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(service)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: screen,
        routes: {
          AppRoutes.main: (_) => const Scaffold(body: Text('PANTALLA PRINCIPAL')),
          AppRoutes.register: (_) => const RegisterScreen(),
        },
      ),
    ),
  );
  return service;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('Pantalla de login', () {
    testWidgets('campos vacíos muestran mensajes de obligatorio', (tester) async {
      await _pump(tester, const LoginScreen());
      await _tap(tester, const Key('login_submit'));
      expect(find.text('El email es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    });

    testWidgets('contraseña incorrecta muestra un mensaje claro', (tester) async {
      await _pump(tester, const LoginScreen());
      await tester.enterText(find.byKey(const Key('login_email')), AppConstants.demoEmail);
      await tester.enterText(find.byKey(const Key('login_password')), 'Incorrecta1');
      await _tap(tester, const Key('login_submit'));
      expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
      expect(find.text('PANTALLA PRINCIPAL'), findsNothing);
    });

    testWidgets('login correcto con el usuario demo navega a la app', (tester) async {
      await _pump(tester, const LoginScreen());
      await tester.enterText(find.byKey(const Key('login_email')), AppConstants.demoEmail);
      await tester.enterText(find.byKey(const Key('login_password')), AppConstants.demoPassword);
      await _tap(tester, const Key('login_submit'));
      expect(find.text('PANTALLA PRINCIPAL'), findsOneWidget);
    });
  });

  group('Pantalla de registro', () {
    Future<void> fill(WidgetTester tester,
        {String name = 'Saúl', String email = 'saul@correo.com', String pass = 'Clave1234', String? confirm}) async {
      await tester.enterText(find.byKey(const Key('register_name')), name);
      await tester.enterText(find.byKey(const Key('register_email')), email);
      await tester.enterText(find.byKey(const Key('register_password')), pass);
      await tester.enterText(find.byKey(const Key('register_confirm')), confirm ?? pass);
    }

    testWidgets('valida nombre, email, contraseña débil y confirmación', (tester) async {
      await _pump(tester, const RegisterScreen());
      await fill(tester, name: '', email: 'correo-malo', pass: 'abc', confirm: 'xyz');
      await _tap(tester, const Key('register_submit'));
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('Escribe un email válido'), findsOneWidget);
      expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('no permite registrar un email duplicado', (tester) async {
      await _pump(tester, const RegisterScreen());
      await fill(tester, email: AppConstants.demoEmail);
      await _tap(tester, const Key('register_submit'));
      expect(find.text('Ya existe una cuenta con ese email'), findsOneWidget);
      expect(find.text('PANTALLA PRINCIPAL'), findsNothing);
    });

    testWidgets('registro válido crea la cuenta y entra a la app', (tester) async {
      final service = await _pump(tester, const RegisterScreen());
      await fill(tester);
      await _tap(tester, const Key('register_submit'));
      expect(find.text('PANTALLA PRINCIPAL'), findsOneWidget);
      expect((await service.currentUser())?.email, 'saul@correo.com');
    });
  });
}
