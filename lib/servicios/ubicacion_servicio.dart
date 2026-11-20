import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';
import '../modelos/ciudad.dart';

enum EstadoUbicacion {
  ok,
  servicioApagado,
  permisoDenegado,
  permisoBloqueado,
  sinCiudadCerca,
  error,
}

class RespuestaUbicacion {
  const RespuestaUbicacion(this.estado, [this.ciudad]);

  final EstadoUbicacion estado;
  final Ciudad? ciudad;

  String get mensaje {
    return switch (estado) {
      EstadoUbicacion.ok => 'Detectamos que estás en ${ciudad?.nombre}.',
      EstadoUbicacion.servicioApagado =>
        'Tu ubicación está desactivada. Actívala o elige tu ciudad de la lista.',
      EstadoUbicacion.permisoDenegado =>
        'No diste permiso de ubicación. Puedes elegir tu ciudad de la lista.',
      EstadoUbicacion.permisoBloqueado =>
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes del teléfono o elige tu ciudad de la lista.',
      EstadoUbicacion.sinCiudadCerca =>
        'Todavía no tenemos planes cerca de ti. Elige una ciudad de la lista.',
      EstadoUbicacion.error =>
        'No pudimos obtener tu ubicación. Elige tu ciudad de la lista.',
    };
  }
}

/// Sugiere la ciudad del usuario con el GPS (RF-PU-04). La ubicación se usa
/// una sola vez y no se guarda: solo se guarda la ciudad que el usuario elige.
class UbicacionServicio {
  Future<RespuestaUbicacion> ciudadCercana(List<Ciudad> ciudades) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const RespuestaUbicacion(EstadoUbicacion.servicioApagado);
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        return const RespuestaUbicacion(EstadoUbicacion.permisoDenegado);
      }
      if (permiso == LocationPermission.deniedForever) {
        return const RespuestaUbicacion(EstadoUbicacion.permisoBloqueado);
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final ciudad = ciudadMasCercana(
        posicion.latitude,
        posicion.longitude,
        ciudades,
      );
      if (ciudad == null) {
        return const RespuestaUbicacion(EstadoUbicacion.sinCiudadCerca);
      }
      return RespuestaUbicacion(EstadoUbicacion.ok, ciudad);
    } catch (e) {
      debugPrint('Error obteniendo la ubicación: $e');
      return const RespuestaUbicacion(EstadoUbicacion.error);
    }
  }
}
