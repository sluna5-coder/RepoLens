import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:repolens/data/cache_repository.dart';
import 'package:repolens/data/favorite_repository.dart';
import 'package:repolens/data/history_repository.dart';
import 'package:repolens/providers/analysis_provider.dart';
import 'package:repolens/providers/auth_provider.dart';
import 'package:repolens/providers/favorites_provider.dart';
import 'package:repolens/providers/history_provider.dart';
import 'package:repolens/providers/theme_provider.dart';
import 'package:repolens/screens/main_shell.dart';
import 'package:repolens/services/auth_service.dart';
import 'package:repolens/services/connectivity_service.dart';
import 'package:repolens/services/github_service.dart';
import 'package:repolens/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fakes.dart';
import '../mocks/mock_responses.dart';

/// Monta el contenedor principal sin sesión (no se toca la base de datos).
Future<void> _pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TokenService>(create: (_) => TokenService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService(FakeUserRepository()))),
        ChangeNotifierProvider(
          create: (_) => AnalysisProvider(
            github: GithubService(client: successClient()),
            cache: CacheRepository(),
            history: HistoryRepository(),
            connectivity: ConnectivityService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => HistoryProvider(HistoryRepository())),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(FavoriteRepository())),
      ],
      child: const MaterialApp(home: MainShell()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la barra inferior navega entre las cinco secciones', (tester) async {
    // Tamaño de teléfono (el lienzo de prueba por defecto es ancho como tableta).
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpShell(tester);

    Future<void> go(String label) async {
      await tester.tap(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
      );
      await tester.pumpAndSettle();
    }

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ANÁLISIS RECIENTES'), findsOneWidget); // Inicio

    await go('Analizar');
    expect(find.text('Listo para analizar'), findsOneWidget);

    await go('Historial');
    expect(find.text('Historial vacío'), findsOneWidget);

    await go('Favoritos');
    expect(find.text('Sin favoritos'), findsOneWidget);

    await go('Perfil');
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await go('Inicio');
    expect(find.text('ANÁLISIS RECIENTES'), findsOneWidget);
  });

  testWidgets('en pantallas anchas (tableta) usa NavigationRail', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpShell(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
