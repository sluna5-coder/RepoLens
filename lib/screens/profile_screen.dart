import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/token_service.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Perfil: datos del usuario, selector de tema, token opcional de GitHub
/// y cierre de sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _token = TextEditingController();
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  /// Solo se consulta si existe un token; su valor nunca se muestra.
  Future<void> _loadToken() async {
    final token = await context.read<TokenService>().read();
    if (mounted) setState(() => _hasToken = token != null && token.isNotEmpty);
  }

  Future<void> _saveToken() async {
    final value = _token.text.trim();
    if (value.isEmpty) {
      showSnack(context, 'Pega un token antes de guardar');
      return;
    }
    try {
      await context.read<TokenService>().save(value);
      _token.clear();
      if (!mounted) return;
      setState(() => _hasToken = true);
      showSnack(context, 'Token guardado en el dispositivo');
    } catch (_) {
      if (mounted) showSnack(context, 'No se pudo guardar el token');
    }
  }

  Future<void> _deleteToken() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Eliminar token',
      message: 'Volverás al límite de 60 peticiones por hora.',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<TokenService>().delete();
      if (!mounted) return;
      setState(() => _hasToken = false);
      showSnack(context, 'Token eliminado');
    } catch (_) {
      if (mounted) showSnack(context, 'No se pudo eliminar el token');
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Cerrar sesión',
      message: '¿Seguro que quieres cerrar tu sesión?',
      confirmLabel: 'Cerrar sesión',
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(user?.name ?? ''),
                  subtitle: Text(
                    '${user?.email ?? ''}\nMiembro desde ${Fmt.date(user?.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 16),
              Text('Tema', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Claro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Oscuro'),
                  ),
                ],
                selected: {themeProvider.mode},
                onSelectionChanged: (selection) => themeProvider.setMode(selection.first),
              ),
              const SizedBox(height: 24),
              Text('Token de GitHub (opcional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Sin token la API permite 60 peticiones por hora; con token, 5000. '
                'Se guarda cifrado solo en este dispositivo.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    _hasToken ? Icons.key : Icons.key_off,
                    color: _hasToken ? AppColors.of(context).green : null,
                  ),
                  title: Text(_hasToken ? 'Token configurado' : 'Sin token'),
                  trailing: _hasToken
                      ? Semantics(
                          label: 'Eliminar token',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Eliminar token',
                            onPressed: _deleteToken,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _token,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Pegar token personal',
                  hintText: 'ghp_...',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _saveToken,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar token'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 24),
              Text(
                '${AppConstants.appName} 1.0.0 · Proyecto final de desarrollo móvil multiplataforma',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
