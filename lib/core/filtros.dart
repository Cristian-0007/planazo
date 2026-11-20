import '../modelos/evento.dart';

/// Cuándo ocurre el evento.
enum FiltroFecha {
  cualquiera('Cualquier fecha'),
  hoy('Hoy'),
  semana('Esta semana'),
  finDeSemana('Fin de semana'),
  mes('Este mes');

  const FiltroFecha(this.etiqueta);

  final String etiqueta;
}

/// Rango de precio en pesos colombianos.
enum FiltroPrecio {
  cualquiera('Cualquier precio'),
  gratis('Gratis'),
  hasta50('Hasta \$50.000'),
  de50a150('\$50.000 a \$150.000'),
  mas150('Más de \$150.000');

  const FiltroPrecio(this.etiqueta);

  final String etiqueta;
}

/// Todo lo que el usuario puede combinar para refinar Explorar (RF-EU-03).
/// Es inmutable: cada cambio crea un objeto nuevo con [copiar].
class FiltrosEventos {
  const FiltrosEventos({
    this.texto = '',
    this.categoriaSlug,
    this.fecha = FiltroFecha.cualquiera,
    this.precio = FiltroPrecio.cualquiera,
    this.localidad,
  });

  /// Búsqueda por texto libre (RF-EU-02).
  final String texto;

  /// null = todas las categorías.
  final String? categoriaSlug;
  final FiltroFecha fecha;
  final FiltroPrecio precio;

  /// Localidad del lugar. null = todas.
  final String? localidad;

  /// Cuántos filtros de la hoja (fecha, precio, ubicación) están activos.
  int get avanzadosActivos =>
      (fecha != FiltroFecha.cualquiera ? 1 : 0) +
      (precio != FiltroPrecio.cualquiera ? 1 : 0) +
      (localidad != null ? 1 : 0);

  /// True si hay cualquier búsqueda o filtro aplicado.
  bool get hayAlgunoActivo =>
      texto.trim().isNotEmpty || categoriaSlug != null || avanzadosActivos > 0;

  /// Para cambiar un campo y poder dejarlo en null, se pasa su "quitar".
  FiltrosEventos copiar({
    String? texto,
    String? categoriaSlug,
    bool quitarCategoria = false,
    FiltroFecha? fecha,
    FiltroPrecio? precio,
    String? localidad,
    bool quitarLocalidad = false,
  }) {
    return FiltrosEventos(
      texto: texto ?? this.texto,
      categoriaSlug: quitarCategoria ? null : (categoriaSlug ?? this.categoriaSlug),
      fecha: fecha ?? this.fecha,
      precio: precio ?? this.precio,
      localidad: quitarLocalidad ? null : (localidad ?? this.localidad),
    );
  }

  /// Quita la fecha, el precio y la ubicación, pero conserva texto y categoría.
  FiltrosEventos sinAvanzados() {
    return FiltrosEventos(texto: texto, categoriaSlug: categoriaSlug);
  }
}

/// Minúsculas y sin tildes, para que "musica" encuentre "Música".
String normalizar(String s) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñ';
  const a = 'aaaaeeeeiiiioooouuuun';
  final b = StringBuffer();
  for (final c in s.toLowerCase().runes) {
    final ch = String.fromCharCode(c);
    final i = de.indexOf(ch);
    b.write(i >= 0 ? a[i] : ch);
  }
  return b.toString();
}

/// Rango [inicio, fin) de cada opción de fecha, según el día de hoy.
/// La semana va de lunes a domingo.
(DateTime, DateTime)? rangoDeFecha(FiltroFecha f, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final lunesSiguiente = DateTime(hoy.year, hoy.month, hoy.day + 8 - hoy.weekday);

  switch (f) {
    case FiltroFecha.cualquiera:
      return null;
    case FiltroFecha.hoy:
      return (hoy, DateTime(hoy.year, hoy.month, hoy.day + 1));
    case FiltroFecha.semana:
      return (hoy, lunesSiguiente);
    case FiltroFecha.finDeSemana:
      // Sábado y domingo. Si ya es fin de semana, empieza hoy.
      final desdeSabado = hoy.weekday >= 6
          ? hoy
          : DateTime(hoy.year, hoy.month, hoy.day + 6 - hoy.weekday);
      return (desdeSabado, lunesSiguiente);
    case FiltroFecha.mes:
      return (hoy, DateTime(hoy.year, hoy.month + 1, 1));
  }
}

bool _cumplePrecio(FiltroPrecio f, int? precio) {
  if (f == FiltroPrecio.cualquiera) return true;
  // Un precio "por confirmar" no se puede comparar: queda fuera si se filtra.
  if (precio == null) return false;
  return switch (f) {
    FiltroPrecio.cualquiera => true,
    FiltroPrecio.gratis => precio == 0,
    FiltroPrecio.hasta50 => precio > 0 && precio <= 50000,
    FiltroPrecio.de50a150 => precio > 50000 && precio <= 150000,
    FiltroPrecio.mas150 => precio > 150000,
  };
}

/// ¿El evento cumple todos los filtros a la vez? (Se combinan con "y").
bool eventoCumple(Evento e, FiltrosEventos f, DateTime ahora) {
  if (f.categoriaSlug != null && e.categoria?.slug != f.categoriaSlug) {
    return false;
  }

  if (f.localidad != null && e.lugar?.localidad != f.localidad) return false;

  if (!_cumplePrecio(f.precio, e.precio)) return false;

  final rango = rangoDeFecha(f.fecha, ahora);
  if (rango != null) {
    final (desde, hasta) = rango;
    final fin = e.terminaEn ?? e.iniciaEn;
    // El evento cuenta si se cruza con el rango (también los de varios días).
    if (!(e.iniciaEn.isBefore(hasta) && !fin.isBefore(desde))) return false;
  }

  // Texto: todas las palabras deben aparecer en nombre, lugar o categoría.
  final palabras = normalizar(f.texto)
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (palabras.isNotEmpty) {
    final pajar = normalizar([
      e.nombre,
      e.lugar?.nombre,
      e.lugar?.localidad,
      e.lugar?.direccion,
      e.categoria?.nombre,
    ].whereType<String>().join(' '));
    if (!palabras.every(pajar.contains)) return false;
  }

  return true;
}

/// Los que cumplen los filtros, ordenados por relevancia (RF-EU-01): primero
/// los de las categorías preferidas del perfil y, dentro de cada grupo, por
/// fecha. Sin preferencias, queda solo el orden por fecha.
List<Evento> aplicarFiltros(
  List<Evento> eventos,
  FiltrosEventos filtros, {
  required DateTime ahora,
  Set<int> categoriasPreferidas = const {},
}) {
  bool preferido(Evento e) {
    final c = e.categoria;
    return c != null && categoriasPreferidas.contains(c.id);
  }

  final lista = eventos.where((e) => eventoCumple(e, filtros, ahora)).toList();
  lista.sort((a, b) {
    final pa = preferido(a) ? 0 : 1;
    final pb = preferido(b) ? 0 : 1;
    if (pa != pb) return pa.compareTo(pb);
    return a.iniciaEn.compareTo(b.iniciaEn);
  });
  return lista;
}

/// Localidades distintas de los eventos, en orden alfabético, para la hoja.
List<String> localidadesDe(Iterable<Evento> eventos) {
  final set = <String>{
    for (final e in eventos)
      if (e.lugar?.localidad != null && e.lugar!.localidad!.trim().isNotEmpty)
        e.lugar!.localidad!,
  };
  return set.toList()..sort((a, b) => normalizar(a).compareTo(normalizar(b)));
}
