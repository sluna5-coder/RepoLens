// Prueba de integración: recorre la app completa en un dispositivo o emulador.
//
// La base de datos SQLite, la sesión y la navegación son las reales. Solo la
// API de GitHub se simula con un MockClient, para que la prueba no dependa de
// la red ni gaste el límite de 60 peticiones por hora.
//
// Ejecutar con un emulador o teléfono conectado:
//   flutter test integration_test/app_test.dart -d <dispositivo>

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:repolens/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../test/mocks/mock_responses.dart';

/// API de GitHub simulada. Cada repo responde con su propio nombre y
/// estrellas; `octocat/no-existe` responde 404.
MockClient fakeGithub() {
  final base = successClient();
  const stars = {'flutter/flutter': 171000, 'octocat/hello-world': 42};
  return MockClient((request) async {
    final segments = request.url.pathSegments; // repos, owner, repo, ...
    if (segments.length < 3 || segments.first != 'repos') {
      return http.Response('{"message":"Not Found"}', 404);
    }
    final fullName = '${segments[1]}/${segments[2]}';
    if (fullName == 'octocat/no-existe') {
      return http.Response('{"message":"Not Found"}', 404);
    }
    if (segments.length == 3) {
      final repo = jsonDecode(repoJson) as Map<String, dynamic>
        ..['full_name'] = fullName
        ..['name'] = segments[2]
        ..['stargazers_count'] = stars[fullName] ?? 1
        ..['owner'] = {'login': segments[1], 'avatar_url': ''};
      return http.Response.bytes(utf8.encode(jsonEncode(repo)), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
    final response = await base.get(request.url, headers: request.headers);
    // Los avatares de ejemplo apuntan a example.com (404): se quitan.
    final body = utf8
        .decode(response.bodyBytes)
        .replaceAll(RegExp(r'https://example\.com/[a-z]\.png'), '');
    return http.Response.bytes(utf8.encode(body), response.statusCode,
        headers: response.headers);
  });
}

/// Avanza fotogramas hasta que [finder] aparezca. Evita `pumpAndSettle`, que
/// no termina mientras haya indicadores de carga animándose.
Future<void> waitFor(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  // Para diagnosticar: textos visibles en ese momento.
  final visible = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .take(40)
      .join(' | ');
  throw TestFailure('No apareció: $finder\nEn pantalla: $visible');
}

/// Toca un elemento y deja que la interfaz responda.
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Campo de texto por su etiqueta.
Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Botón (de cualquier tipo de Material) que contiene [text].
Finder button(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

/// Pestaña de la barra de navegación inferior.
Finder navTab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Escribe una URL en la pantalla Analizar y la envía.
Future<void> analyze(WidgetTester tester, String url) async {
  await tap(tester, navTab('Analizar'));
  await tester.enterText(field('URL del repositorio'), url);
  await tap(tester, button('Analizar'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Estado limpio: base de datos y preferencias vacías.
    await deleteDatabase(p.join(await getDatabasesPath(), 'repolens.db'));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('flujo completo de RepoLens', (tester) async {
    await tester.pumpWidget(RepoLensApp(httpClient: fakeGithub()));
    await waitFor(tester, find.text('Iniciar sesión'));

    // 1. Registro: primero con errores de validación, luego válido.
    await tap(tester, find.text('¿No tienes cuenta? Regístrate'));
    await waitFor(tester, find.byKey(const Key('register_submit')));
    await tap(tester, find.byKey(const Key('register_submit')));
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('El email es obligatorio'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register_name')), 'Ana Prueba');
    await tester.enterText(find.byKey(const Key('register_email')), 'ana@correo');
    await tester.enterText(find.byKey(const Key('register_password')), 'corta');
    await tester.enterText(find.byKey(const Key('register_confirm')), 'otra');
    await tap(tester, find.byKey(const Key('register_submit')));
    expect(find.text('Escribe un email válido'), findsOneWidget);
    expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register_email')), 'ana@correo.com');
    await tester.enterText(find.byKey(const Key('register_password')), 'Segura123');
    await tester.enterText(find.byKey(const Key('register_confirm')), 'Segura123');
    await tap(tester, find.byKey(const Key('register_submit')));
    await waitFor(tester, find.text('Hola, Ana'));

    // Para probar el login, primero se cierra la sesión.
    await tap(tester, navTab('Perfil'));
    await tap(tester, button('Cerrar sesión'));
    await tap(tester, button('Cerrar sesión').last);
    await waitFor(tester, find.text('Iniciar sesión'));

    // 2. Login fallido y luego correcto.
    await tester.enterText(find.byKey(const Key('login_email')), 'ana@correo.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'Equivocada1');
    await tap(tester, find.byKey(const Key('login_submit')));
    await waitFor(tester, find.text('Email o contraseña incorrectos'));

    // Tras un fallo la app pide esperar antes del siguiente intento.
    await Future<void>.delayed(const Duration(seconds: 3));
    await tester.enterText(find.byKey(const Key('login_password')), 'Segura123');
    await tap(tester, find.byKey(const Key('login_submit')));
    await waitFor(tester, find.text('Hola, Ana'));

    // 3. Analizar flutter/flutter y un repo pequeño, recorrer pestañas y
    //    agregar a favoritos.
    await analyze(tester, 'https://github.com/flutter/flutter');
    // Se espera el informe (el texto flutter/flutter también es un acceso rápido).
    await waitFor(tester, find.byKey(const Key('favorite_button')));
    expect(find.text('flutter/flutter'), findsWidgets);
    for (final tab in ['Lenguajes', 'Commits', 'Archivos', 'README', 'Salud', 'Resumen']) {
      await tap(tester, find.widgetWithText(Tab, tab));
    }
    await tap(tester, find.byKey(const Key('favorite_button')));
    await tester.enterText(find.byKey(const Key('note_field')), 'Framework de referencia');
    await tap(tester, button('Guardar'));
    await waitFor(tester, find.text('Guardado en favoritos'));
    await tap(tester, find.byType(BackButton));

    await analyze(tester, 'github.com/octocat/hello-world');
    await waitFor(tester, find.byKey(const Key('favorite_button')));
    expect(find.text('octocat/hello-world'), findsWidgets);
    await tap(tester, find.widgetWithText(Tab, 'Salud'));
    expect(find.text('Puntuación de salud'), findsOneWidget);
    await tap(tester, find.byType(BackButton));

    // 4. Editar la nota y eliminar el favorito.
    await tap(tester, navTab('Favoritos'));
    await waitFor(tester, find.textContaining('Framework de referencia'));
    await tap(tester, find.byTooltip('Editar nota'));
    await tester.enterText(find.byKey(const Key('note_field')), 'Nota editada');
    await tap(tester, button('Guardar'));
    await waitFor(tester, find.textContaining('Nota editada'));
    await tap(tester, find.byTooltip('Eliminar'));
    await tap(tester, button('Eliminar').last);
    await waitFor(tester, find.text('Sin favoritos'));

    // 5. Historial: los dos análisis quedaron guardados.
    await tap(tester, navTab('Historial'));
    await waitFor(tester, find.text('flutter/flutter'));
    expect(find.text('octocat/hello-world'), findsOneWidget);

    // 6. URL inválida y repo inexistente.
    await analyze(tester, 'esto no es una url');
    await waitFor(tester, find.textContaining('URL inválida'));
    await analyze(tester, 'https://github.com/octocat/no-existe');
    await waitFor(tester, find.textContaining('No se encontró el repositorio'));
    expect(button('Reintentar'), findsOneWidget);

    // 7. Comparar dos repos.
    await tap(tester, navTab('Inicio'));
    await tap(tester, find.text('Comparar'));
    await waitFor(tester, field('Repositorio A'));
    await tester.enterText(field('Repositorio A'), 'https://github.com/flutter/flutter');
    await tester.enterText(field('Repositorio B'), 'https://github.com/octocat/hello-world');
    await tap(tester, button('Comparar'));
    await waitFor(tester, find.text('171.0k'));
    await tap(tester, find.byType(BackButton));

    // 8. Cambiar el tema y cerrar sesión.
    await tap(tester, navTab('Perfil'));
    expect(Theme.of(tester.element(find.text('Tema'))).brightness, Brightness.dark);
    await tap(tester, find.text('Claro'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Theme.of(tester.element(find.text('Tema'))).brightness, Brightness.light);
    await tap(tester, button('Cerrar sesión'));
    await tap(tester, button('Cerrar sesión').last);
    await waitFor(tester, find.text('Iniciar sesión'));
  });
}
