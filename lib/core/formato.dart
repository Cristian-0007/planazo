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
