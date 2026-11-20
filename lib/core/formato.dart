// Utilidades para mostrar fechas y precios en español, sin depender de
// paquetes de localización.

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String mesCorto(DateTime f) => _meses[f.month - 1];

String diaCorto(DateTime f) => _dias[f.weekday - 1];

String hora12(DateTime f) {
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final m = f.minute.toString().padLeft(2, '0');
  final sufijo = f.hour < 12 ? 'a. m.' : 'p. m.';
  return '$h:$m $sufijo';
}

/// Ejemplo: "Sáb 7 nov · 8:00 p. m."
String fechaYHora(DateTime f) =>
    '${diaCorto(f)} ${f.day} ${mesCorto(f)} · ${hora12(f)}';

String conMiles(int n) {
  return n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

/// 0 = Gratis, null = precio no informado.
String textoPrecio(int? precio) {
  if (precio == null) return 'Precio por confirmar';
  if (precio == 0) return 'Gratis';
  return '\$${conMiles(precio)}';
}

/// Días de calendario entre dos fechas (sin contar las horas).
int diasEntre(DateTime desde, DateTime hasta) {
  final a = DateTime.utc(desde.year, desde.month, desde.day);
  final b = DateTime.utc(hasta.year, hasta.month, hasta.day);
  return b.difference(a).inDays;
}

/// Encabezado de día para la agenda: "Hoy", "Mañana" o "Sáb 7 nov".
String etiquetaDia(DateTime f, DateTime ahora) {
  return switch (diasEntre(ahora, f)) {
    0 => 'Hoy',
    1 => 'Mañana',
    _ => '${diaCorto(f)} ${f.day} ${mesCorto(f)}',
  };
}

/// Tiempo transcurrido en lenguaje corriente: "Ahora", "Hace 5 min",
/// "Hace 3 h", "Ayer" o "7 nov".
String haceCuanto(DateTime f, DateTime ahora) {
  final d = ahora.difference(f);
  if (d.isNegative || d.inMinutes < 1) return 'Ahora';
  if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
  if (d.inHours < 24 && diasEntre(f, ahora) == 0) return 'Hace ${d.inHours} h';
  if (diasEntre(f, ahora) == 1) return 'Ayer';
  return '${f.day} ${mesCorto(f)}';
}
