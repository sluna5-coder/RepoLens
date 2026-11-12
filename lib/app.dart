import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/cache_repository.dart';
import 'data/favorite_repository.dart';
import 'data/history_repository.dart';
import 'data/user_repository.dart';
import 'models/analysis_result.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/history_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/compare_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/github_service.dart';
import 'services/token_service.dart';

/// Nombres de las rutas de navegación.
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String result = '/result';
  static const String compare = '/compare';
}

/// Raíz de la app: registra los providers (inyección de dependencias),
/// los temas claro/oscuro y las rutas.
class RepoLensApp extends StatelessWidget {
  const RepoLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Al crearse borra el token global de la versión anterior.
        Provider<TokenService>(create: (_) => TokenService()..deleteLegacy()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService(UserRepository()))),
        ChangeNotifierProvider(
          create: (ctx) => AnalysisProvider(
            // El servicio lee en cada petición el token del usuario con sesión
            // activa; sin sesión no se envía ningún token.
            github: GithubService(tokenProvider: () async {
              final id = ctx.read<AuthProvider>().user?.id;
              return id == null ? null : ctx.read<TokenService>().read(id);
            }),
            cache: CacheRepository(),
            history: HistoryRepository(),
            connectivity: ConnectivityService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => HistoryProvider(HistoryRepository())),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(FavoriteRepository())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.main: (_) => const MainShell(),
            AppRoutes.compare: (_) => const CompareScreen(),
          },
          // La ruta de detalle recibe el informe como argumento.
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.result) {
              final result = settings.arguments as AnalysisResult;
              return MaterialPageRoute(builder: (_) => ResultScreen(result: result));
            }
            return null;
          },
        ),
      ),
    );
  }
}
