import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/geo.dart';
import 'package:planazo/modelos/ciudad.dart';
import 'package:planazo/modelos/perfil.dart';

void main() {
  const bogota = Ciudad(
    id: 'bog',
    nombre: 'Bogotá',
    latitud: 4.711,
    longitud: -74.0721,
  );
  const medellin = Ciudad(
    id: 'med',
    nombre: 'Medellín',
    latitud: 6.2442,
    longitud: -75.5812,
  );
  const sinCoordenadas = Ciudad(id: 'x', nombre: 'Sin coordenadas');

  group('distanciaKm', () {
    test('el mismo punto está a 0 km', () {
      expect(distanciaKm(4.711, -74.0721, 4.711, -74.0721), closeTo(0, 0.001));
    });

    test('Bogotá y Medellín están a unos 240 km', () {
      expect(
        distanciaKm(4.711, -74.0721, 6.2442, -75.5812),
        closeTo(240, 10),
      );
    });
  });

  group('ciudadMasCercana', () {
    test('elige Bogotá para un punto dentro de la ciudad', () {
      expect(ciudadMasCercana(4.65, -74.1, [bogota])?.id, 'bog');
    });

    test('devuelve null si ninguna ciudad está dentro del radio', () {
      expect(ciudadMasCercana(6.2442, -75.5812, [bogota]), isNull);
    });

    test('con varias ciudades elige la más cercana', () {
      expect(ciudadMasCercana(6.25, -75.56, [bogota, medellin])?.id, 'med');
    });

    test('ignora ciudades sin coordenadas', () {
      expect(ciudadMasCercana(4.65, -74.1, [sinCoordenadas, bogota])?.id, 'bog');
      expect(ciudadMasCercana(4.65, -74.1, [sinCoordenadas]), isNull);
    });
  });

  group('Perfil.desdeJson', () {
    test('lee todos los campos, incluida la ciudad anidada', () {
      final p = Perfil.desdeJson({
        'nombre': 'Ana',
        'telefono': '3001234567',
        'ciudad_id': 'bog',
        'onboarding_completo': true,
        'acepta_terminos': true,
        'acepto_en': '2026-11-07T15:30:00Z',
        'notificaciones_activas': false,
        'personalizacion_activa': true,
        'ciudades': {'nombre': 'Bogotá'},
      });
      expect(p.nombre, 'Ana');
      expect(p.telefono, '3001234567');
      expect(p.ciudadId, 'bog');
      expect(p.ciudadNombre, 'Bogotá');
      expect(p.onboardingCompleto, isTrue);
      expect(p.aceptaTerminos, isTrue);
      expect(p.aceptoEn, isNotNull);
      expect(p.notificacionesActivas, isFalse);
      expect(p.personalizacionActiva, isTrue);
    });

    test('con campos ausentes usa valores por defecto', () {
      final p = Perfil.desdeJson({'nombre': 'Luis'});
      expect(p.telefono, isNull);
      expect(p.ciudadId, isNull);
      expect(p.ciudadNombre, isNull);
      expect(p.onboardingCompleto, isFalse);
      expect(p.aceptaTerminos, isFalse);
      expect(p.aceptoEn, isNull);
      expect(p.notificacionesActivas, isTrue);
      expect(p.personalizacionActiva, isTrue);
    });
  });
}
