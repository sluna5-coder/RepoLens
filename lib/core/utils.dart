/// Utilidades de formato usadas en varias pantallas.
class Fmt {
  /// Fecha corta dd/mm/aaaa.
  static String date(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year}';
  }

  /// Fecha con hora dd/mm/aaaa hh:mm.
  static String dateTime(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${date(l)} ${_two(l.hour)}:${_two(l.minute)}';
  }

  /// Números grandes abreviados: 1500 -> 1.5k.
  static String compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  /// Tamaño en KB (como lo entrega GitHub) a texto legible.
  static String sizeKb(int kb) {
    if (kb >= 1024 * 1024) return '${(kb / 1024 / 1024).toStringAsFixed(1)} GB';
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(1)} MB';
    return '$kb KB';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
