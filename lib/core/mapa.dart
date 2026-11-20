import 'package:url_launcher/url_launcher.dart';

/// Abre Google Maps (app o navegador) en el lugar indicado.
/// Usa coordenadas si existen; si no, nombre + dirección.
Future<bool> abrirMapa({
  double? latitud,
  double? longitud,
  String? nombre,
  String? direccion,
}) async {
  final consulta = (latitud != null && longitud != null)
      ? '$latitud,$longitud'
      : [nombre, direccion]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
  if (consulta.isEmpty) return false;

  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': consulta,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}