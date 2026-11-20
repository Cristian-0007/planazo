/// Datos del perfil del usuario (tabla `perfiles`).
class Perfil {
  const Perfil({
    required this.nombre,
    required this.onboardingCompleto,
    required this.aceptaTerminos,
    required this.notificacionesActivas,
    required this.personalizacionActiva,
    this.telefono,
    this.ciudadId,
    this.ciudadNombre,
    this.aceptoEn,
  });

  final String nombre;
  final String? telefono;
  final String? ciudadId;
  final String? ciudadNombre;
  final bool onboardingCompleto;

  /// Autorización de tratamiento de datos dada al registrarse. La app solo
  /// la muestra; no puede modificarla.
  final bool aceptaTerminos;
  final DateTime? aceptoEn;

  /// Avisos dentro de la app sobre eventos guardados.
  final bool notificacionesActivas;

  /// Usar las categorías de interés para ordenar Explorar.
  final bool personalizacionActiva;

  factory Perfil.desdeJson(Map<String, dynamic> j) {
    final ciudad = j['ciudades'];
    return Perfil(
      nombre: j['nombre'] as String,
      telefono: j['telefono'] as String?,
      ciudadId: j['ciudad_id'] as String?,
      ciudadNombre: ciudad is Map<String, dynamic>
          ? ciudad['nombre'] as String?
          : null,
      onboardingCompleto: j['onboarding_completo'] == true,
      aceptaTerminos: j['acepta_terminos'] == true,
      aceptoEn: j['acepto_en'] == null
          ? null
          : DateTime.parse(j['acepto_en'] as String).toLocal(),
      notificacionesActivas: j['notificaciones_activas'] != false,
      personalizacionActiva: j['personalizacion_activa'] != false,
    );
  }
}
