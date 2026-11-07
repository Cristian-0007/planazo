class Categoria {
  const Categoria({
    required this.id,
    required this.slug,
    required this.nombre,
  });

  final int id;
  final String slug;
  final String nombre;

  factory Categoria.desdeJson(Map<String, dynamic> j) {
    return Categoria(
      id: (j['id'] as num).toInt(),
      slug: j['slug'] as String,
      nombre: j['nombre'] as String,
    );
  }
}

class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    this.direccion,
    this.localidad,
    this.latitud,
    this.longitud,
  });

  final String id;
  final String nombre;
  final String? direccion;
  final String? localidad;
  final double? latitud;
  final double? longitud;

  factory Lugar.desdeJson(Map<String, dynamic> j) {
    return Lugar(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      direccion: j['direccion'] as String?,
      localidad: j['localidad'] as String?,
      latitud: (j['latitud'] as num?)?.toDouble(),
      longitud: (j['longitud'] as num?)?.toDouble(),
    );
  }
}

class Evento {
  const Evento({
    required this.id,
    required this.nombre,
    required this.iniciaEn,
    required this.estado,
    this.descripcion,
    this.imagenUrl,
    this.terminaEn,
    this.precio,
    this.edadMinima,
    this.lugar,
    this.categoria,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final DateTime iniciaEn;
  final DateTime? terminaEn;

  /// En pesos colombianos. 0 = gratis, null = no informado.
  final int? precio;
  final int? edadMinima;

  /// 'proximo', 'en_curso', 'sin_cupos', 'cancelado' o 'finalizado'.
  /// Lo calcula la base de datos en la vista eventos_con_estado.
  final String estado;

  final Lugar? lugar;
  final Categoria? categoria;

  factory Evento.desdeJson(
    Map<String, dynamic> j, {
    Lugar? lugar,
    Categoria? categoria,
  }) {
    return Evento(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      descripcion: j['descripcion'] as String?,
      imagenUrl: j['imagen_url'] as String?,
      iniciaEn: DateTime.parse(j['inicia_en'] as String).toLocal(),
      terminaEn: j['termina_en'] == null
          ? null
          : DateTime.parse(j['termina_en'] as String).toLocal(),
      precio: (j['precio'] as num?)?.toInt(),
      edadMinima: (j['edad_minima'] as num?)?.toInt(),
      estado: j['estado'] as String,
      lugar: lugar,
      categoria: categoria,
    );
  }
}
