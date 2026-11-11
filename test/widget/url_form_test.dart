import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/widgets/state_views.dart';
import 'package:repolens/widgets/url_form.dart';
import 'package:repolens/core/exceptions.dart';

void main() {
  group('Formulario de URL', () {
    late List<String> submitted;

    Future<void> pump(WidgetTester tester) async {
      submitted = [];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: UrlForm(onSubmit: submitted.add)),
      ));
    }

    testWidgets('URL inválida muestra error y no envía', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), 'https://gitlab.com/a/b');
      await tester.tap(find.text('Analizar'));
      await tester.pump();
      expect(find.textContaining('URL inválida'), findsOneWidget);
      expect(submitted, isEmpty);
    });

    testWidgets('campo vacío pide pegar una URL', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Analizar'));
      await tester.pump();
      expect(find.text('Pega la URL de un repositorio'), findsOneWidget);
      expect(submitted, isEmpty);
    });

    testWidgets('URL válida se envía sin errores', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), ' github.com/flutter/flutter ');
      await tester.tap(find.text('Analizar'));
      await tester.pump();
      expect(submitted, ['github.com/flutter/flutter']);
      expect(find.textContaining('URL inválida'), findsNothing);
    });
  });

  testWidgets('ErrorView muestra el mensaje y el botón Reintentar funciona', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorView(error: const NoConnectionException(), onRetry: () => retries++),
      ),
    ));
    expect(find.textContaining('Sin conexión a internet'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });
}
