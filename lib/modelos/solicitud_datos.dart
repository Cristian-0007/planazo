/// Solicitud del titular sobre sus datos personales (tabla `solicitudes_datos`).
class SolicitudDatos {
  const SolicitudDatos({
    required this.id,
    required this.tipo,
    required this.detalle,
    required this.estado,
    required this.creadaEn,
    this.respuesta,
    this.responderAntesDe,
  });

  final String id;

  /// 'acceso', 'actualizacion', 'correccion' o 'eliminacion'.
  final String tipo;
  final String detalle;

  /// 'recibida', 'en_proceso', 'resuelta' o 'rechazada'.
  final String estado;
  final String? respuesta;
  final DateTime creadaEn;
  final DateTime? responderAntesDe;

  bool get abierta => estado == 'recibida' || estado == 'en_proceso';

  factory SolicitudDatos.desdeJson(Map<String, dynamic> j) {
    return SolicitudDatos(
      id: j['id'] as String,
      tipo: j['tipo'] as String,
      detalle: j['detalle'] as String,
      estado: j['estado'] as String,
      respuesta: j['respuesta'] as String?,
      creadaEn: DateTime.parse(j['creada_en'] as String).toLocal(),
      responderAntesDe: j['responder_antes_de'] == null
          ? null
          : DateTime.parse(j['responder_antes_de'] as String).toLocal(),
    );
  }
}

/// Tipos de solicitud que puede hacer el titular (RF-CGD-01).
class TipoSolicitud {
  const TipoSolicitud(this.clave, this.titulo, this.descripcion, this.diasHabiles);

  final String clave;
  final String titulo;
  final String descripcion;

  /// Plazo máximo de respuesta, en días hábiles.
  final int diasHabiles;

  static const todos = <TipoSolicitud>[
    TipoSolicitud(
      'acceso',
      'Conocer mis datos',
      'Pide una copia de los datos personales que tenemos sobre ti.',
      10,
    ),
    TipoSolicitud(
      'actualizacion',
      'Actualizar mis datos',
      'Pide que pongamos al día datos que cambiaron.',
      15,
    ),
    TipoSolicitud(
      'correccion',
      'Corregir mis datos',
      'Pide que arreglemos datos que están mal.',
      15,
    ),
    TipoSolicitud(
      'eliminacion',
      'Eliminar mis datos',
      'Pide que borremos tus datos y revoquemos tu autorización.',
      15,
    ),
  ];

  static TipoSolicitud de(String clave) {
    return todos.firstWhere((t) => t.clave == clave, orElse: () => todos.first);
  }
}

String textoEstadoSolicitud(String estado) {
  return switch (estado) {
    'recibida' => 'Recibida',
    'en_proceso' => 'En proceso',
    'resuelta' => 'Resuelta',
    'rechazada' => 'Rechazada',
    _ => estado,
  };
}
