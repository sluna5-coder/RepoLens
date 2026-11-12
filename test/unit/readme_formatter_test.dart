import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/readme_formatter.dart';

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
  });
}
