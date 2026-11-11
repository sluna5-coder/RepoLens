import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/history_provider.dart';
import 'analyze_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal con la navegación entre las cinco secciones.
/// En teléfonos usa NavigationBar (abajo) y en tabletas NavigationRail (lado).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home, label: 'Inicio'),
    (icon: Icons.search_outlined, selected: Icons.search, label: 'Analizar'),
    (icon: Icons.history_outlined, selected: Icons.history, label: 'Historial'),
    (icon: Icons.star_outline, selected: Icons.star, label: 'Favoritos'),
    (icon: Icons.person_outline, selected: Icons.person, label: 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    // Al entrar se cargan el historial y los favoritos del usuario desde SQLite.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;
      context.read<HistoryProvider>().load(userId);
      context.read<FavoritesProvider>().load(userId);
    });
  }

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // IndexedStack conserva el estado de cada pestaña al cambiar de sección.
    final body = IndexedStack(
      index: _index,
      children: [
        HomeScreen(onNavigate: _go),
        const AnalyzeScreen(),
        const HistoryScreen(),
        const FavoritesScreen(),
        const ProfileScreen(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 720;
        if (isTablet) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _go,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
