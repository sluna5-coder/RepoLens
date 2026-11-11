import 'package:flutter_test/flutter_test.dart';
import 'package:repolens/core/validators.dart';

void main() {
  group('Parser de URL de repositorio', () {
    test('acepta https://github.com/owner/repo', () {
      expect(Validators.parseRepoUrl('https://github.com/flutter/flutter'), 'flutter/flutter');
    });

    test('acepta la URL sin protocolo', () {
      expect(Validators.parseRepoUrl('github.com/dart-lang/http'), 'dart-lang/http');
    });

    test('acepta la variante con .git', () {
      expect(Validators.parseRepoUrl('https://github.com/owner/repo.git'), 'owner/repo');
    });

    test('acepta la variante con /tree/...', () {
      expect(
        Validators.parseRepoUrl('https://github.com/owner/my.repo/tree/main/lib'),
        'owner/my.repo',
      );
    });

    test('ignora espacios, www y barra final', () {
      expect(Validators.parseRepoUrl('  http://www.github.com/a-b/c_d/  '), 'a-b/c_d');
    });

    test('rechaza URLs inválidas', () {
      const invalid = [
        '',
        'hola mundo',
        'https://gitlab.com/owner/repo',
        'https://github.com/soloowner',
        'https://github.com/',
        'github.com//repo',
        'https://example.com/github.com/owner/repo',
      ];
      for (final url in invalid) {
        expect(Validators.parseRepoUrl(url), isNull, reason: url);
      }
    });

    test('el validador del campo devuelve mensaje en URL inválida o vacía', () {
      expect(Validators.repoUrl(''), 'Pega la URL de un repositorio');
      expect(Validators.repoUrl('no-es-url'), contains('URL inválida'));
      expect(Validators.repoUrl('https://github.com/flutter/flutter'), isNull);
    });
  });

  group('Validaciones de registro y login', () {
    test('email inválido se rechaza y válido se acepta', () {
      expect(Validators.email(''), 'El email es obligatorio');
      expect(Validators.email('correo-sin-arroba'), 'Escribe un email válido');
      expect(Validators.email('a@b'), 'Escribe un email válido');
      expect(Validators.email('demo@repolens.app'), isNull);
    });

    test('contraseña débil se rechaza', () {
      expect(Validators.password(''), 'La contraseña es obligatoria');
      expect(Validators.password('Ab1'), 'Debe tener al menos 8 caracteres');
      expect(Validators.password('12345678'), 'Debe incluir al menos una letra');
      expect(Validators.password('abcdefgh'), 'Debe incluir al menos un número');
      expect(Validators.password('Demo1234'), isNull);
    });

    test('la confirmación debe coincidir', () {
      expect(Validators.confirmPassword('Demo1235', 'Demo1234'), 'Las contraseñas no coinciden');
      expect(Validators.confirmPassword('Demo1234', 'Demo1234'), isNull);
    });

    test('nombre y campos obligatorios', () {
      expect(Validators.name('   '), 'El nombre es obligatorio');
      expect(Validators.name('Saúl'), isNull);
      expect(Validators.required('', 'El email es obligatorio'), 'El email es obligatorio');
    });

    test('la nota de favorito admite máximo 300 caracteres', () {
      expect(Validators.note('a' * 300), isNull);
      expect(Validators.note('a' * 301), isNotNull);
      expect(Validators.note(''), isNull);
    });
  });
}
