import 'dart:math' as math;

import '../modelos/ciudad.dart';

/// Distancia en kilómetros entre dos puntos (fórmula de Haversine).
double distanciaKm(double lat1, double lon1, double lat2, double lon2) {
  const radioTierraKm = 6371.0;
  double rad(double grados) => grados * math.pi / 180;

  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final s1 = math.sin(dLat / 2);
  final s2 = math.sin(dLon / 2);
  final a = s1 * s1 + math.cos(rad(lat1)) * math.cos(rad(lat2)) * s2 * s2;
  return 2 * radioTierraKm * math.asin(math.sqrt(a));
}

/// La ciudad con coordenadas más cercana al punto, si está a menos de
/// [radioKm]. Devuelve null si ninguna queda dentro del radio.
Ciudad? ciudadMasCercana(
  double latitud,
  double longitud,
  List<Ciudad> ciudades, {
  double radioKm = 60,
}) {
  Ciudad? mejor;
  var mejorDistancia = double.infinity;
  for (final c in ciudades) {
    final lat = c.latitud;
    final lon = c.longitud;
    if (lat == null || lon == null) continue;
    final d = distanciaKm(latitud, longitud, lat, lon);
    if (d <= radioKm && d < mejorDistancia) {
      mejor = c;
      mejorDistancia = d;
    }
  }
  return mejor;
}
