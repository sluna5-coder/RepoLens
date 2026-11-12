import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/readme_formatter.dart';
import 'package:repolens/core/url_policy.dart';

void main() {
  final f = ReadmeFormatter(fullName: 'octocat/demo', branch: 'main');
  const raw = 'https://raw.githubusercontent.com/octocat/demo/main/';

  group('ReadmeFormatter', () {
    test('convierte <img> con ruta relativa en imagen Markdown absoluta', () {
      final md = f.format('<p align="center">\n  <img src="assets/logo.svg" width="72" alt="Logo">\n</p>');
      expect(md, '![Logo](${raw}assets/logo.svg#72x)');
    });

    test('las imágenes de una tabla HTML salen una por una', () {
      final md = f.format('<table><tr><td><img src="a.png"></td><td><img src="./b.png"></td></tr></table>');
      expect(md, contains('![](${raw}a.png)'));
      expect(md, contains('![](${raw}b.png)'));
      expect(md, isNot(contains('<td>')));
    });

    test('encabezados, enlaces y saltos de línea HTML', () {
      final md = f.format('<h1 align="center">De Peón a Rey</h1>\n'
          '<a href="docs/guia.md"><strong>Guía</strong></a><br>fin');
      expect(md, contains('# De Peón a Rey'));
      expect(md, contains('[**Guía**](https://github.com/octocat/demo/blob/main/docs/guia.md)'));
      expect(md, contains('  \nfin'));
    });

    test('resuelve rutas relativas en la sintaxis Markdown', () {
      expect(f.format('![Captura](/docs/c.png "titulo")'), '![Captura](${raw}docs/c.png "titulo")');
    });

    test('<picture> conserva solo la imagen principal', () {
      final md = f.format('<picture><source srcset="dark.png"><img src="light.png" alt="X"></picture>');
      expect(md, '![X](${raw}light.png)');
    });

    test('no toca el HTML dentro de bloques de código', () {
      const code = '```dart\nfinal List<String> a = [];\n<img src="x.png">\n```';
      expect(f.format(code), code);
    });

    test('convierte enlaces blob de GitHub a archivos crudos', () {
      expect(f.resolveImage('https://github.com/a/b/blob/dev/img/x.png?raw=true'),
          'https://raw.githubusercontent.com/a/b/dev/img/x.png');
      expect(f.resolveImage('https://img.shields.io/badge/x-y-blue'),
          'https://img.shields.io/badge/x-y-blue');
    });
    test('codifica la rama por segmento en las URLs', () {
      final g = ReadmeFormatter(fullName: 'a/b', branch: 'feature/año #1');
      expect(g.resolveImage('img.png'),
          'https://raw.githubusercontent.com/a/b/feature/a%C3%B1o%20%231/img.png');
      expect(g.resolveLink('docs/x.md'), 'https://github.com/a/b/blob/feature/a%C3%B1o%20%231/docs/x.md');
    });

    test('quita comentarios HTML, incluso uno sin cerrar', () {
      expect(f.format('a<!-- oculto -->b'), 'ab');
      expect(f.format('visible<!-- sin cerrar'), 'visible');
    });

    test('recorta un README muy largo y lo indica', () {
      final short = ReadmeFormatter.limit('corto');
      expect(short.truncated, isFalse);
      expect(short.text, 'corto');

      final long = ReadmeFormatter.limit('linea\n' * 100, 50);
      expect(long.truncated, isTrue);
      expect(long.text.length, lessThanOrEqualTo(50));
      expect(long.text.endsWith('linea'), isTrue); // se corta en un salto de línea

      final huge = formatReadme(['a/b', 'main', 'x\n' * 200000]);
      expect(huge.truncated, isTrue);
    });

    test('un README malicioso de 200 KB se formatea rápido (sin ReDoS)', () {
      final sw = Stopwatch()..start();
      final filler = 'x' * 150000;
      for (final evil in [
        '<img ' * 40000, '<picture>' * 22000, '<a href=x>' * 20000, '![' * 100000,
        '<h1>' * 50000, '<!--' * 50000,
        // Justo debajo del tope de etiquetas: se procesan con los límites acotados.
        '<img ' * 4900 + filler, '<h1>' * 4900 + filler, '<a>' * 4900 + filler,
        '<picture>' * 4900 + filler, '![' * 4900 + filler,
      ]) {
        formatReadme(['a/b', 'main', evil]);
      }
      // Antes del arreglo uno solo de estos textos tardaba minutos.
      expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });

  group('UrlPolicy', () {
    test('solo carga solas las imágenes de hosts confiables por HTTPS', () {
      bool trusted(String url) => UrlPolicy.isTrustedImage(Uri.parse(url));
      expect(trusted('https://raw.githubusercontent.com/a/b/main/x.png'), isTrue);
      expect(trusted('https://user-images.githubusercontent.com/1/x.png'), isTrue);
      expect(trusted('https://github.com/a/b/raw/main/x.png'), isTrue);
      expect(trusted('https://img.shields.io/badge/x-y-blue'), isTrue);
      expect(trusted('https://badgen.net/npm/v/x'), isTrue);
      expect(trusted('https://tracker.example.com/pixel.gif'), isFalse);
      expect(trusted('https://evilgithubusercontent.com/x.png'), isFalse);
      expect(trusted('https://githubusercontent.com.evil.io/x.png'), isFalse);
      expect(trusted('https://notbadgen.net/x.svg'), isFalse);
      expect(trusted('http://raw.githubusercontent.com/a/b/main/x.png'), isFalse);
    });

    test('solo los enlaces de GitHub se abren sin confirmar', () {
      bool github(String url) => UrlPolicy.isGithubLink(Uri.parse(url));
      expect(github('https://github.com/a/b'), isTrue);
      expect(github('https://docs.github.com/es'), isTrue);
      expect(github('https://octocat.github.io/demo'), isTrue);
      expect(github('https://github.com.evil.io/login'), isFalse);
      expect(github('https://evilgithub.io'), isFalse);
      expect(github('mailto:a@b.com'), isFalse);
    });
  });
}
