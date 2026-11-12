import 'constants.dart';

/// Prepara el README de GitHub para el visor de Markdown de la app.
///
/// GitHub acepta HTML dentro del Markdown (`<img>`, `<p align>`, `<table>`)
/// y rutas relativas al repositorio. El visor de Flutter descarta el HTML y no
/// sabe a qué repositorio pertenece una ruta como `docs/captura.png`. Esta
/// clase convierte lo más común a Markdown y vuelve absolutas las rutas.
/// Es lógica pura, sin Flutter, para poder probarla.
///
/// Seguridad: el README lo escribe cualquiera. Las expresiones usan
/// cuantificadores acotados (`{0,N}`) para que un texto malicioso no dispare
/// un retroceso catastrófico, y antes se recorta el texto con [limit].
class ReadmeFormatter {
  ReadmeFormatter({required this.fullName, required this.branch});

  /// `owner/repo`.
  final String fullName;
  final String branch;

  /// Rama codificada por segmento (`feature/a b` -> `feature/a%20b`).
  String get _branchPath => branch.split('/').map(Uri.encodeComponent).join('/');

  /// Base para imágenes: archivos crudos del repositorio.
  String get _rawBase => 'https://raw.githubusercontent.com/$fullName/$_branchPath/';

  /// Base para enlaces: la vista del archivo en GitHub.
  String get _blobBase => 'https://github.com/$fullName/blob/$_branchPath/';

  /// Recorta el README a [maxChars] caracteres (en el último salto de línea
  /// antes del límite) e indica si hubo recorte.
  static ({String text, bool truncated}) limit(String markdown,
      [int maxChars = AppConstants.maxReadmeChars]) {
    if (markdown.length <= maxChars) return (text: markdown, truncated: false);
    final cut = markdown.lastIndexOf('\n', maxChars);
    return (text: markdown.substring(0, cut > 0 ? cut : maxChars), truncated: true);
  }

  static final _fence = RegExp(r'^(```|~~~)', multiLine: true);
  static final _picture = RegExp(r'<picture\b[^>]{0,1000}>(.{0,3000}?)</picture>',
      caseSensitive: false, dotAll: true);
  static final _img =
      RegExp(r'<img\b([^>]{0,1000}?)/?>', caseSensitive: false, dotAll: true);
  static final _heading = RegExp(r'<h([1-6])\b[^>]{0,1000}>(.{0,1000}?)</h\1>',
      caseSensitive: false, dotAll: true);
  static final _anchor = RegExp(r'<a\b([^>]{0,1000})>(.{0,2000}?)</a>',
      caseSensitive: false, dotAll: true);
  static final _br = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final _bold = RegExp(r'</?(strong|b)>', caseSensitive: false);
  static final _italic = RegExp(r'</?(em|i)>', caseSensitive: false);
  static final _summary = RegExp(r'<summary\b[^>]{0,1000}>(.{0,1000}?)</summary>',
      caseSensitive: false, dotAll: true);

  /// Etiquetas de estructura que se quitan dejando su contenido.
  static final _layoutTags = RegExp(
    r'</?(p|div|span|center|table|thead|tbody|tfoot|tr|td|th|sub|sup|details|'
    r'source|picture|kbd|small|section|article|figure|figcaption)\b[^>]{0,1000}>',
    caseSensitive: false,
  );
  static final _mdImage = RegExp(
      r'!\[([^\]]{0,500})\]\(\s{0,100}<?([^)\s>]{1,2000})>?(\s{1,100}"[^"]{0,500}")?\s{0,100}\)');
  static final _blankLines = RegExp(r'\n{3,}');

  /// Con más etiquetas o imágenes que esto no es un README normal: se omite
  /// esa conversión para que el costo no crezca con un texto hecho a propósito.
  static const int _maxTags = 5000;

  /// Cuenta apariciones de [token] (se detiene al pasar de [_maxTags]).
  static int _count(String text, String token) {
    var n = 0;
    for (var i = text.indexOf(token); i >= 0; i = text.indexOf(token, i + token.length)) {
      if (++n > _maxTags) break;
    }
    return n;
  }

  /// Devuelve el Markdown listo para mostrarse.
  String format(String markdown) {
    // Se procesa solo fuera de los bloques de código, para no tocar ejemplos
    // como `List<String>` o fragmentos de HTML que el autor quiso mostrar.
    final buffer = StringBuffer();
    var inCode = false;
    var cursor = 0;
    for (final match in _fence.allMatches(markdown)) {
      final chunk = markdown.substring(cursor, match.start);
      buffer.write(inCode ? chunk : _convert(chunk));
      buffer.write(match.group(0));
      cursor = match.end;
      inCode = !inCode;
    }
    final rest = markdown.substring(cursor);
    buffer.write(inCode ? rest : _convert(rest));
    return buffer.toString().replaceAll(_blankLines, '\n\n').trim();
  }

  String _convert(String text) {
    var s = _stripComments(text);
    if (_count(s, '<') > _maxTags) return _convertMarkdownOnly(s);
    // <picture>: GitHub elige la imagen según el tema; aquí basta la <img>.
    s = s.replaceAllMapped(_picture, (m) {
      final img = _img.firstMatch(m.group(1)!);
      return img?.group(0) ?? '';
    });
    s = s.replaceAllMapped(_img, (m) {
      final attrs = m.group(1)!;
      final src = _attr(attrs, 'src');
      if (src == null || src.isEmpty) return '';
      final alt = (_attr(attrs, 'alt') ?? '').replaceAll(RegExp(r'[\[\]\n]'), ' ');
      final width = int.tryParse(_attr(attrs, 'width') ?? '');
      final height = int.tryParse(_attr(attrs, 'height') ?? '');
      // Formato de tamaño del visor de Markdown: #ANCHOxALTO (cualquiera puede faltar).
      final size = width != null || height != null ? '#${width ?? ''}x${height ?? ''}' : '';
      final url = resolveImage(src) + size;
      return '\n\n![$alt]($url)\n\n';
    });
    s = s.replaceAllMapped(_heading, (m) {
      final level = int.parse(m.group(1)!);
      return '\n\n${'#' * level} ${_inline(m.group(2)!)}\n\n';
    });
    s = s.replaceAllMapped(_anchor, (m) {
      final href = _attr(m.group(1)!, 'href');
      final label = m.group(2)!.trim();
      if (href == null || label.isEmpty) return label;
      // Un enlace que solo envuelve una imagen (insignias): se deja la imagen.
      if (label.startsWith('![')) return label;
      return '[${_inline(label)}](${resolveLink(href)})';
    });
    s = s.replaceAllMapped(_summary, (m) => '\n\n**${_inline(m.group(1)!)}**\n\n');
    s = s.replaceAll(_br, '  \n');
    s = s.replaceAll(_bold, '**').replaceAll(_italic, '_');
    s = s.replaceAll(_layoutTags, '\n');
    return _convertMarkdownOnly(s);
  }

  /// Parte que no depende del HTML: rutas de imágenes Markdown y sangrías.
  String _convertMarkdownOnly(String text) {
    var s = text;
    // Imágenes en sintaxis Markdown con ruta relativa.
    if (_count(s, '![') <= _maxTags) {
      s = s.replaceAllMapped(_mdImage, (m) {
        final title = m.group(3) ?? '';
        return '![${m.group(1)}](${resolveImage(m.group(2)!)}$title)';
      });
    }
    // Las líneas con sangría que vienen del HTML se leerían como bloques de
    // código: se quita la sangría solo a imágenes, enlaces y encabezados.
    s = s.split('\n').map((l) => l.trim().isEmpty ? '' : l).join('\n');
    return s.replaceAll(RegExp(r'^[ \t]+(?=!\[|\[|#{1,6} |\*\*)', multiLine: true), '');
  }

  /// Quita los comentarios HTML en tiempo lineal (sin expresión regular).
  /// Un comentario sin cerrar llega hasta el final, como en GitHub.
  static String _stripComments(String text) {
    final out = StringBuffer();
    var i = 0;
    while (true) {
      final start = text.indexOf('<!--', i);
      if (start < 0) break;
      out.write(text.substring(i, start));
      final end = text.indexOf('-->', start + 4);
      if (end < 0) return out.toString();
      i = end + 3;
    }
    out.write(text.substring(i));
    return out.toString();
  }

  /// Texto en línea dentro de un encabezado o enlace, sin saltos.
  String _inline(String html) => html
      .replaceAll(_br, ' ')
      .replaceAll(_bold, '**')
      .replaceAll(_italic, '_')
      .replaceAll(RegExp(r'<[^>]{1,1000}>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Valor de un atributo HTML (`src="x"`, `src='x'` o `src=x`).
  static String? _attr(String attrs, String name) {
    final m = RegExp('\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))',
            caseSensitive: false)
        .firstMatch(attrs);
    if (m == null) return null;
    return (m.group(1) ?? m.group(2) ?? m.group(3))?.trim();
  }

  /// URL absoluta para una imagen del README.
  String resolveImage(String src) {
    final url = src.trim();
    if (url.startsWith('data:')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Imagen de GitHub vista como página (blob): se pide el archivo crudo.
      final blob = RegExp(r'^https?://github\.com/([^/]+/[^/]+)/(?:blob|raw)/(.+?)(\?raw=true)?$')
          .firstMatch(url);
      if (blob != null) {
        return 'https://raw.githubusercontent.com/${blob.group(1)}/${blob.group(2)}';
      }
      return url;
    }
    return _rawBase + _relative(url);
  }

  /// URL absoluta para un enlace del README.
  String resolveLink(String href) {
    final url = href.trim();
    if (url.startsWith('#') ||
        url.startsWith('mailto:') ||
        url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('//')) return 'https:$url';
    return _blobBase + _relative(url);
  }

  static String _relative(String path) {
    var p = path;
    while (p.startsWith('./')) {
      p = p.substring(2);
    }
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    return p;
  }
}

/// Recorta y formatea un README. Es de nivel superior para poder usarse con
/// `compute` (fuera del hilo de la interfaz). Recibe `[fullName, rama, texto]`.
({String text, bool truncated}) formatReadme(List<String> args) {
  final limited = ReadmeFormatter.limit(args[2]);
  final formatter = ReadmeFormatter(fullName: args[0], branch: args[1]);
  return (text: formatter.format(limited.text), truncated: limited.truncated);
}
