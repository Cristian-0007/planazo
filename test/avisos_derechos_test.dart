import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/formato.dart';
import 'package:planazo/core/legal.dart';
import 'package:planazo/modelos/notificacion.dart';
import 'package:planazo/modelos/solicitud_datos.dart';

void main() {
  group('Notificacion', () {
    final json = {
      'id': 'n1',
      'evento_id': 'e1',
      'tipo': 'inicio_proximo',
      'mensaje': 'Empieza pronto: "Concierto".',
      'creada_en': '2026-11-19T21:00:00+00:00',
      'leida': false,
    };

    test('desdeJson lee todos los campos', () {
      final n = Notificacion.desdeJson(json);
      expect(n.id, 'n1');
      expect(n.eventoId, 'e1');
      expect(n.tipo, 'inicio_proximo');
      expect(n.leida, isFalse);
      expect(n.creadaEn.toUtc(), DateTime.utc(2026, 11, 19, 21));
    });

    test('marcadaLeida solo cambia la bandera', () {
      final n = Notificacion.desdeJson(json);
      final l = n.marcadaLeida();
      expect(l.leida, isTrue);
      expect(l.id, n.id);
      expect(l.mensaje, n.mensaje);
      expect(l.creadaEn, n.creadaEn);
    });
  });

  group('haceCuanto', () {
    final ahora = DateTime(2026, 11, 19, 16, 0);

    test('segundos y fechas futuras: Ahora', () {
      expect(haceCuanto(DateTime(2026, 11, 19, 15, 59, 40), ahora), 'Ahora');
      expect(haceCuanto(DateTime(2026, 11, 19, 17, 0), ahora), 'Ahora');
    });

    test('minutos y horas del mismo día', () {
      expect(haceCuanto(DateTime(2026, 11, 19, 15, 55), ahora), 'Hace 5 min');
      expect(haceCuanto(DateTime(2026, 11, 19, 13, 0), ahora), 'Hace 3 h');
    });

    test('ayer, aunque hayan pasado menos de 24 horas', () {
      expect(haceCuanto(DateTime(2026, 11, 18, 23, 0), ahora), 'Ayer');
    });

    test('más antiguo: día y mes', () {
      expect(haceCuanto(DateTime(2026, 11, 17, 10, 0), ahora), '17 nov');
    });
  });

  group('SolicitudDatos', () {
    test('desdeJson y abierta', () {
      final s = SolicitudDatos.desdeJson({
        'id': 's1',
        'tipo': 'eliminacion',
        'detalle': 'Quiero borrar mi cuenta',
        'estado': 'recibida',
        'respuesta': null,
        'creada_en': '2026-11-19T15:00:00+00:00',
        'responder_antes_de': '2026-12-11T15:00:00+00:00',
      });
      expect(s.abierta, isTrue);
      expect(s.respuesta, isNull);
      expect(s.responderAntesDe, isNotNull);
      expect(textoEstadoSolicitud(s.estado), 'Recibida');
    });

    test('resuelta y rechazada no están abiertas', () {
      for (final estado in ['resuelta', 'rechazada']) {
        final s = SolicitudDatos.desdeJson({
          'id': 's',
          'tipo': 'acceso',
          'detalle': 'Quiero ver mis datos',
          'estado': estado,
          'creada_en': '2026-11-19T15:00:00+00:00',
        });
        expect(s.abierta, isFalse);
      }
    });

    test('plazos: 10 días hábiles para consultas y 15 para reclamos', () {
      expect(TipoSolicitud.de('acceso').diasHabiles, 10);
      expect(TipoSolicitud.de('actualizacion').diasHabiles, 15);
      expect(TipoSolicitud.de('correccion').diasHabiles, 15);
      expect(TipoSolicitud.de('eliminacion').diasHabiles, 15);
    });

    test('un tipo desconocido cae en el primero', () {
      expect(TipoSolicitud.de('otro').clave, 'acceso');
    });
  });

  test('la política tiene secciones con texto y menciona el canal de la app', () {
    final secciones = seccionesPolitica();
    expect(secciones, isNotEmpty);
    for (final s in secciones) {
      expect(s.titulo, isNotEmpty);
      expect(s.parrafos, isNotEmpty);
    }
    final todo = secciones.expand((s) => s.parrafos).join(' ');
    expect(todo, contains('Mis derechos'));
    expect(todo, contains('1581'));
  });
}
