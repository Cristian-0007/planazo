import 'package:flutter/material.dart';

/// Degradado de cada categoría, tomado del kit de diseño. Se usa como
/// imagen de reemplazo cuando el evento no trae foto.
LinearGradient degradadoCategoria(String? slug) {
  final (inicio, fin) = switch (slug) {
    'musica' => (const Color(0xFFF5407E), const Color(0xFF7B2FF7)),
    'cine' => (const Color(0xFF2E2B6B), const Color(0xFF5B8CFF)),
    'gastronomia' => (const Color(0xFFE2561B), const Color(0xFFFFC93C)),
    'deportes' => (const Color(0xFF0E7C5A), const Color(0xFF4FE0B0)),
    'arte' => (const Color(0xFF7B2FF7), const Color(0xFFF5407E)),
    'cultura' => (const Color(0xFF9C4A12), const Color(0xFFFFC93C)),
    'entretenimiento' => (const Color(0xFFB3145C), const Color(0xFFFF8A3D)),
    'actividad-fisica' => (const Color(0xFF1A5FB4), const Color(0xFF4FE0B0)),
    _ => (const Color(0xFF2A2158), const Color(0xFF39306B)),
  };
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inicio, fin],
  );
}

IconData iconoCategoria(String? slug) {
  return switch (slug) {
    'musica' => Icons.music_note,
    'cine' => Icons.movie_outlined,
    'gastronomia' => Icons.restaurant,
    'deportes' => Icons.sports_soccer,
    'arte' => Icons.palette_outlined,
    'cultura' => Icons.theater_comedy_outlined,
    'entretenimiento' => Icons.celebration_outlined,
    'actividad-fisica' => Icons.directions_run,
    _ => Icons.event,
  };
}
