import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

/// Inicio de sesión con validación de campos obligatorios y mensaje claro
/// cuando las credenciales son incorrectas.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 1) Validaciones del formulario. 2) Consulta a SQLite vía AuthProvider.
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text, _password.text);
    if (!mounted || !ok) return;
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  /// Rellena el formulario con el usuario de prueba.
  void _fillDemo() {
    _email.text = AppConstants.demoEmail;
    _password.text = AppConstants.demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: MaxWidth(
            maxWidth: 440,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: AppLogo()),
                  const SizedBox(height: 16),
                  Text('Iniciar sesión',
                      style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('login_email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'El email es obligatorio'),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('login_password'),
                    controller: _password,
                    obscureText: _obscure,
                    validator: (v) => Validators.required(v, 'La contraseña es obligatoria'),
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: Semantics(
                        label: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                        button: true,
                        child: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.error!,
                      key: const Key('login_error'),
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('login_submit'),
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: const Text('Usuario de prueba'),
                      subtitle: const Text(
                          '${AppConstants.demoEmail}\n${AppConstants.demoPassword}'),
                      isThreeLine: true,
                      trailing: TextButton(onPressed: _fillDemo, child: const Text('Usar')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
