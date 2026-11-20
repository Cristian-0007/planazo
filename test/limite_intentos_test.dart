import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/limite_intentos.dart';

void main() {
  group('LimiteIntentos', () {
    late DateTime ahora;
    late LimiteIntentos limite;

    setUp(() {
      ahora = DateTime(2026, 11, 19, 10, 0);
      limite = LimiteIntentos(reloj: () => ahora);
    });

    test('4 fallos no bloquean y el quinto sí', () {
      for (var i = 0; i < 4; i++) {
        expect(limite.registrarFallo('a@b.co'), isFalse);
      }
      expect(limite.estaBloqueado('a@b.co'), isFalse);
      expect(limite.intentosRestantes('a@b.co'), 1);

      expect(limite.registrarFallo('a@b.co'), isTrue);
      expect(limite.estaBloqueado('a@b.co'), isTrue);
      expect(limite.segundosRestantes('a@b.co'), 300);
    });

    test('el bloqueo termina a los 5 minutos y el contador vuelve a cero', () {
      for (var i = 0; i < 5; i++) {
        limite.registrarFallo('a@b.co');
      }
      ahora = ahora.add(const Duration(minutes: 2));
      expect(limite.segundosRestantes('a@b.co'), 180);

      ahora = ahora.add(const Duration(minutes: 3));
      expect(limite.segundosRestantes('a@b.co'), 0);
      expect(limite.intentosRestantes('a@b.co'), 5);
    });

    test('ignora mayúsculas y espacios en el correo', () {
      for (var i = 0; i < 5; i++) {
        limite.registrarFallo(' A@B.co ');
      }
      expect(limite.estaBloqueado('a@b.co'), isTrue);
    });

    test('cada correo lleva su propia cuenta', () {
      for (var i = 0; i < 5; i++) {
        limite.registrarFallo('a@b.co');
      }
      expect(limite.estaBloqueado('otro@b.co'), isFalse);
      expect(limite.intentosRestantes('otro@b.co'), 5);
    });

    test('limpiar borra fallos y bloqueo', () {
      for (var i = 0; i < 5; i++) {
        limite.registrarFallo('a@b.co');
      }
      limite.limpiar('a@b.co');
      expect(limite.estaBloqueado('a@b.co'), isFalse);
      expect(limite.intentosRestantes('a@b.co'), 5);
    });
  });

  test('textoEspera', () {
    expect(textoEspera(300), '5 minutos');
    expect(textoEspera(60), '1 minuto');
    expect(textoEspera(61), '2 minutos');
    expect(textoEspera(45), '45 segundos');
    expect(textoEspera(1), '1 segundo');
  });
}
