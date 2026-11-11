import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/exceptions.dart';
import '../core/utils.dart';
import '../core/validators.dart';
import '../models/analysis_result.dart';
import '../providers/analysis_provider.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Compara dos repositorios lado a lado. Reutiliza `AnalysisProvider.load`,
/// así que también aprovecha la caché.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _second = TextEditingController();

  bool _loading = false;
  AppException? _error;
  AnalysisResult? _a;
  AnalysisResult? _b;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final provider = context.read<AnalysisProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Los dos informes se piden en paralelo.
      final results = await Future.wait([
        provider.load(_first.text),
        provider.load(_second.text),
      ]);
      _a = results[0];
      _b = results[1];
    } on AppException catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar repositorios')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidth(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _first,
                      enabled: !_loading,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      validator: Validators.repoUrl,
                      decoration: const InputDecoration(
                        labelText: 'Repositorio A',
                        hintText: 'https://github.com/owner/repo',
                        prefixIcon: Icon(Icons.looks_one_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _second,
                      enabled: !_loading,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      validator: Validators.repoUrl,
                      decoration: const InputDecoration(
                        labelText: 'Repositorio B',
                        hintText: 'https://github.com/owner/repo',
                        prefixIcon: Icon(Icons.looks_two_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _compare,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Comparar'),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const LoadingView(message: 'Analizando ambos repositorios...')
              else if (_error != null)
                ErrorView(error: _error!, onRetry: _compare)
              else if (_a != null && _b != null)
                _CompareTable(a: _a!, b: _b!)
              else
                const EmptyState(
                  icon: Icons.compare_arrows,
                  title: 'Compara dos repositorios',
                  message: 'Escribe las dos URLs para ver sus datos lado a lado.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tabla lado a lado; resalta en negritas el valor ganador de cada fila.
class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.a, required this.b});

  final AnalysisResult a;
  final AnalysisResult b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    TableRow header() => TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
          children: [
            _cell(''),
            _cell(a.repo.fullName, bold: true),
            _cell(b.repo.fullName, bold: true),
          ],
        );

    // Fila numérica: gana el mayor (o el menor si lowerWins).
    TableRow number(String label, int va, int vb, {bool lowerWins = false}) {
      final aWins = lowerWins ? va < vb : va > vb;
      final bWins = lowerWins ? vb < va : vb > va;
      return TableRow(children: [
        _cell(label),
        _cell(Fmt.compact(va), bold: aWins),
        _cell(Fmt.compact(vb), bold: bWins),
      ]);
    }

    TableRow text(String label, String va, String vb) =>
        TableRow(children: [_cell(label), _cell(va), _cell(vb)]);

    String join(List<String> items) => items.isEmpty ? '—' : items.join(', ');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            HealthGauge(score: a.healthScore, size: 90),
            HealthGauge(score: b.healthScore, size: 90),
          ],
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: theme.dividerColor),
          columnWidths: const {
            0: FlexColumnWidth(1.1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            header(),
            number('Salud', a.healthScore, b.healthScore),
            number('Estrellas', a.repo.stars, b.repo.stars),
            number('Forks', a.repo.forks, b.repo.forks),
            number('Watchers', a.repo.watchers, b.repo.watchers),
            number('Issues abiertos', a.repo.openIssues, b.repo.openIssues, lowerWins: true),
            number('Alertas', a.alerts.length, b.alerts.length, lowerWins: true),
            text('Lenguaje principal', a.languages.isEmpty ? '—' : a.languages.first.name,
                b.languages.isEmpty ? '—' : b.languages.first.name),
            text('Stack', join(a.stacks), join(b.stacks)),
            text('Licencia', a.repo.license ?? 'Sin licencia', b.repo.license ?? 'Sin licencia'),
            text('Tamaño', Fmt.sizeKb(a.repo.sizeKb), Fmt.sizeKb(b.repo.sizeKb)),
            text('Creado', Fmt.date(a.repo.createdAt), Fmt.date(b.repo.createdAt)),
            text('Actualizado', Fmt.date(a.repo.updatedAt), Fmt.date(b.repo.updatedAt)),
          ],
        ),
      ],
    );
  }

  Widget _cell(String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      );
}
