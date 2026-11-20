import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/formato.dart';

void main() {
  test('textoPrecio: gratis, con miles y por confirmar', () {
    expect(textoPrecio(0), 'Gratis');
    expect(textoPrecio(45000), '\$45.000');
    expect(textoPrecio(1250000), '\$1.250.000');
    expect(textoPrecio(null), 'Precio por confirmar');
  });

  test('hora12: formato de 12 horas en español', () {
    expect(hora12(DateTime(2026, 11, 7, 20, 0)), '8:00 p. m.');
    expect(hora12(DateTime(2026, 11, 7, 0, 5)), '12:05 a. m.');
    expect(hora12(DateTime(2026, 11, 7, 12, 0)), '12:00 p. m.');
  });

  test('fechaYHora: el 7 de noviembre de 2026 es sábado', () {
    expect(fechaYHora(DateTime(2026, 11, 7, 20, 0)), 'Sáb 7 nov · 8:00 p. m.');
  });

  test('etiquetaDia: hoy, mañana y fecha corta', () {
    final ahora = DateTime(2026, 11, 7, 15, 30);
    expect(etiquetaDia(DateTime(2026, 11, 7, 23, 0), ahora), 'Hoy');
    expect(etiquetaDia(DateTime(2026, 11, 8, 0, 5), ahora), 'Mañana');
    expect(etiquetaDia(DateTime(2026, 11, 10, 20, 0), ahora), 'Mar 10 nov');
  });

  test('diasEntre: cuenta días de calendario, no horas', () {
    expect(diasEntre(DateTime(2026, 11, 7, 23, 59), DateTime(2026, 11, 8, 0, 1)), 1);
    expect(diasEntre(DateTime(2026, 11, 7, 8), DateTime(2026, 11, 7, 22)), 0);
  });
}
