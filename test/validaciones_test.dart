import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/validaciones.dart';

void main() {
  group('evaluarClave', () {
    test('cumple con 8 caracteres, mayúscula, minúscula y número', () {
      expect(evaluarClave('Planazo26').cumple, isTrue);
    });

    test('marca cada regla por separado', () {
      final r = evaluarClave('planazo');
      expect(r.largo, isFalse);
      expect(r.mayuscula, isFalse);
      expect(r.minuscula, isTrue);
      expect(r.numero, isFalse);
      expect(r.cumple, isFalse);
    });

    test('reconoce mayúsculas con tilde y la eñe', () {
      final r = evaluarClave('Ñandú2026');
      expect(r.mayuscula, isTrue);
      expect(r.minuscula, isTrue);
      expect(r.cumple, isTrue);
    });
  });

  group('validarClaveNueva', () {
    test('acepta una contraseña que cumple las reglas', () {
      expect(validarClaveNueva('Planazo26'), isNull);
    });

    test('rechaza vacía, débil y demasiado larga', () {
      expect(validarClaveNueva(''), 'Escribe una contraseña.');
      expect(validarClaveNueva(null), 'Escribe una contraseña.');
      expect(
        validarClaveNueva('planazo26'),
        'La contraseña no cumple las reglas de seguridad.',
      );
      expect(validarClaveNueva('Aa1${'x' * 80}'), 'Usa máximo 72 caracteres.');
    });
  });

  group('validarCorreo', () {
    test('acepta y rechaza formatos', () {
      expect(validarCorreo(' ana@correo.com '), isNull);
      expect(validarCorreo('ana@correo'), 'Escribe un correo válido.');
      expect(validarCorreo(''), 'Escribe un correo válido.');
    });
  });

  group('validarNombre', () {
    test('pide al menos 2 letras y máximo 80', () {
      expect(validarNombre('Ana'), isNull);
      expect(validarNombre(' A '), 'Escribe tu nombre.');
      expect(validarNombre('a' * 81), 'Usa máximo 80 caracteres.');
    });
  });

  group('teléfono', () {
    test('normalizarTelefono quita espacios, guiones y paréntesis', () {
      expect(normalizarTelefono('300 123-4567'), '3001234567');
      expect(normalizarTelefono('+57 (300) 123 4567'), '+573001234567');
      expect(normalizarTelefono('   '), isNull);
      expect(normalizarTelefono(null), isNull);
    });

    test('validarTelefono: opcional, pero con 7 a 15 dígitos si se escribe', () {
      expect(validarTelefono(''), isNull);
      expect(validarTelefono('300 123 4567'), isNull);
      expect(validarTelefono('+573001234567'), isNull);
      expect(validarTelefono('12345'), isNotNull);
      expect(validarTelefono('abc1234567'), isNotNull);
    });
  });

  group('validarCodigo', () {
    test('solo dígitos, de 6 a 10', () {
      expect(validarCodigo('123456'), isNull);
      expect(validarCodigo(' 12345678 '), isNull);
      expect(validarCodigo('12345'), isNotNull);
      expect(validarCodigo('12a456'), isNotNull);
      expect(validarCodigo(''), isNotNull);
    });
  });
}
