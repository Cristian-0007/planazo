class Ciudad {
  const Ciudad({
    required this.id,
    required this.nombre,
    this.latitud,
    this.longitud,
  });

  final String id;
  final String nombre;
  final double? latitud;
  final double? longitud;

  factory Ciudad.desdeJson(Map<String, dynamic> j) {
    return Ciudad(
      id: j['id'] as String,
      nombre: j['nombre'] as String,
      latitud: (j['latitud'] as num?)?.toDouble(),
      longitud: (j['longitud'] as num?)?.toDouble(),
    );
  }
}
