import 'package:flutter/material.dart';

import '../core/validators.dart';

/// Formulario reutilizable para pegar la URL de un repositorio.
/// Valida con [Validators.repoUrl] y entrega la URL solo si es correcta.
class UrlForm extends StatefulWidget {
  const UrlForm({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    this.buttonLabel = 'Analizar',
    this.initialValue,
  });

  /// Recibe el texto ya validado.
  final ValueChanged<String> onSubmit;
  final bool enabled;
  final String buttonLabel;
  final String? initialValue;

  @override
  State<UrlForm> createState() => _UrlFormState();
}

class _UrlFormState extends State<UrlForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      widget.onSubmit(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            validator: Validators.repoUrl,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'URL del repositorio',
              hintText: 'https://github.com/owner/repo',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: Semantics(
                label: 'Borrar texto',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Borrar texto',
                  onPressed: _controller.clear,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.enabled ? _submit : null,
            icon: const Icon(Icons.search),
            label: Text(widget.buttonLabel),
          ),
        ],
      ),
    );
  }
}
