/// Aviso dentro de la app (tabla `notificaciones`).
class Notificacion {
  const Notificacion({
    required this.id,
    required this.eventoId,
    required this.tipo,
    required this.mensaje,
    required this.creadaEn,
    required this.leida,
  });

  final String id;
  final String eventoId;

  /// 'cancelacion', 'sin_cupos' o 'inicio_proximo'.
  final String tipo;
  final String mensaje;
  final DateTime creadaEn;
  final bool leida;

  factory Notificacion.desdeJson(Map<String, dynamic> j) {
    return Notificacion(
      id: j['id'] as String,
      eventoId: j['evento_id'] as String,
      tipo: j['tipo'] as String,
      mensaje: j['mensaje'] as String,
      creadaEn: DateTime.parse(j['creada_en'] as String).toLocal(),
      leida: j['leida'] == true,
    );
  }

  Notificacion marcadaLeida() {
    return Notificacion(
      id: id,
      eventoId: eventoId,
      tipo: tipo,
      mensaje: mensaje,
      creadaEn: creadaEn,
      leida: true,
    );
  }
}
