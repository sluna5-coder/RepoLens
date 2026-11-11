import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/url_form.dart';

/// Lanza un análisis desde cualquier pantalla: muestra el resultado si sale
/// bien y refresca el historial. Devuelve `true` si hubo informe.
Future<bool> runAnalysis(BuildContext context, String input, {bool force = false}) async {
  final analysis = context.read<AnalysisProvider>();
  final history = context.read<HistoryProvider>();
  final userId = context.read<AuthProvider>().user!.id!;

  final result = await analysis.analyze(input, userId: userId, force: force);
  if (result == null) return false;
  await history.load(userId);
  if (!context.mounted) return true;
  if (analysis.warning != null) showSnack(context, analysis.warning!);
  Navigator.pushNamed(context, AppRoutes.result, arguments: result);
  return true;
}

/// Pantalla Analizar: formulario de URL y estados de carga y error.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  /// Última URL enviada: es la que usa el botón Reintentar.
  String? _lastInput;

  static const _examples = ['flutter/flutter', 'dart-lang/http', 'torvalds/linux'];

  void _analyze(String input) {
    _lastInput = input;
    runAnalysis(context, input);
  }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();
    final loading = analysis.status == AnalysisStatus.loading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar repositorio'),
        actions: [
          Semantics(
            label: 'Comparar dos repositorios',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Comparar dos repositorios',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.compare),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pega la URL de un repositorio público de GitHub',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              UrlForm(onSubmit: _analyze, enabled: !loading),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final example in _examples)
                    ActionChip(
                      label: Text(example),
                      onPressed:
                          loading ? null : () => _analyze('https://github.com/$example'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: LoadingView(message: 'Consultando la API de GitHub...'),
                )
              else if (analysis.status == AnalysisStatus.error && analysis.error != null)
                ErrorView(
                  error: analysis.error!,
                  onRetry: () {
                    if (_lastInput != null) _analyze(_lastInput!);
                  },
                )
              else
                const EmptyState(
                  icon: Icons.travel_explore,
                  title: 'Listo para analizar',
                  message: 'Verás datos generales, lenguajes, commits, archivos, '
                      'README, puntuación de salud y alertas de seguridad.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
