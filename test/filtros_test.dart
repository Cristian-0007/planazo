import 'package:flutter_test/flutter_test.dart';
import 'package:planazo/core/filtros.dart';
import 'package:planazo/modelos/evento.dart';

const _musica = Categoria(id: 1, slug: 'musica', nombre: 'Música');
const _cine = Categoria(id: 2, slug: 'cine', nombre: 'Cine');

const _teatro = Lugar(
  id: 'l1',
  nombre: 'Teatro Mayor',
  direccion: 'Calle 170 # 67-51',
  localidad: 'Suba',
);
const _cinemateca = Lugar(
  id: 'l2',
  nombre: 'Cinemateca de Bogotá',
  localidad: 'Santa Fe',
);

Evento _evento(
  String id,
  String nombre, {
  required DateTime inicia,
  DateTime? termina,
  int? precio,
  Categoria categoria = _musica,
  Lugar lugar = _teatro,
}) {
  return Evento(
    id: id,
    nombre: nombre,
    iniciaEn: inicia,
    terminaEn: termina,
    estado: 'proximo',
    precio: precio,
    categoria: categoria,
    lugar: lugar,
  );
}

void main() {
  // Sábado 7 de noviembre de 2026, 3:00 p. m.
  final ahora = DateTime(2026, 11, 7, 15);

  final concierto = _evento('a', 'Concierto de Jazz',
      inicia: DateTime(2026, 11, 7, 20), precio: 80000);
  final peli = _evento('b', 'Festival de cine',
      inicia: DateTime(2026, 11, 10, 18),
      precio: 0,
      categoria: _cine,
      lugar: _cinemateca);
  final lejano = _evento('c', 'Ópera',
      inicia: DateTime(2026, 12, 20, 19), precio: 200000);
  final sinPrecio = _evento('d', 'Feria', inicia: DateTime(2026, 11, 8, 10));
  final todos = [lejano, peli, concierto, sinPrecio];

  List<String> ids(List<Evento> l) => l.map((e) => e.id).toList();

  test('normalizar: minúsculas y sin tildes', () {
    expect(normalizar('MÚSICA Ópera Año'), 'musica opera ano');
  });

  test('búsqueda por texto: ignora tildes y mayúsculas', () {
    final r = aplicarFiltros(todos, const FiltrosEventos(texto: 'musica'),
        ahora: ahora);
    // La categoría "Música" coincide en tres eventos; salen por fecha.
    expect(ids(r), ['a', 'd', 'c']);
    final r2 =
        aplicarFiltros(todos, const FiltrosEventos(texto: 'OPERA'), ahora: ahora);
    expect(ids(r2), ['c']);
  });

  test('búsqueda por texto: busca en lugar y todas las palabras deben aparecer', () {
    final porLugar = aplicarFiltros(
        todos, const FiltrosEventos(texto: 'cinemateca'), ahora: ahora);
    expect(ids(porLugar), ['b']);
    final dosPalabras = aplicarFiltros(
        todos, const FiltrosEventos(texto: 'jazz teatro'), ahora: ahora);
    expect(ids(dosPalabras), ['a']);
    final ninguno = aplicarFiltros(
        todos, const FiltrosEventos(texto: 'jazz cinemateca'), ahora: ahora);
    expect(ninguno, isEmpty);
  });

  test('filtro de precio', () {
    List<String> con(FiltroPrecio p) =>
        ids(aplicarFiltros(todos, FiltrosEventos(precio: p), ahora: ahora));
    expect(con(FiltroPrecio.gratis), ['b']);
    expect(con(FiltroPrecio.de50a150), ['a']);
    expect(con(FiltroPrecio.mas150), ['c']);
    // Con precio por confirmar no se puede filtrar: queda fuera.
    expect(con(FiltroPrecio.hasta50), isEmpty);
    expect(con(FiltroPrecio.cualquiera), hasLength(4));
  });

  test('filtro de fecha: hoy, fin de semana, semana y mes', () {
    List<String> con(FiltroFecha f) =>
        ids(aplicarFiltros(todos, FiltrosEventos(fecha: f), ahora: ahora));
    expect(con(FiltroFecha.hoy), ['a']);
    // Hoy es sábado: el fin de semana va de hoy hasta el domingo.
    expect(con(FiltroFecha.finDeSemana), ['a', 'd']);
    // La semana termina el domingo 8: el martes 10 ya es otra semana.
    expect(con(FiltroFecha.semana), ['a', 'd']);
    expect(con(FiltroFecha.mes), ['a', 'd', 'b']);
  });

  test('un evento de varios días que ya empezó cuenta para "hoy"', () {
    final feria = _evento('f', 'Feria larga',
        inicia: DateTime(2026, 11, 5, 9), termina: DateTime(2026, 11, 9, 18));
    final r = aplicarFiltros([feria], const FiltrosEventos(fecha: FiltroFecha.hoy),
        ahora: ahora);
    expect(ids(r), ['f']);
  });

  test('filtro por categoría y localidad se combinan', () {
    final r = aplicarFiltros(
      todos,
      const FiltrosEventos(categoriaSlug: 'cine', localidad: 'Santa Fe'),
      ahora: ahora,
    );
    expect(ids(r), ['b']);
    final vacio = aplicarFiltros(
      todos,
      const FiltrosEventos(categoriaSlug: 'cine', localidad: 'Suba'),
      ahora: ahora,
    );
    expect(vacio, isEmpty);
  });

  test('relevancia: las categorías preferidas van primero, luego por fecha', () {
    final sin = aplicarFiltros(todos, const FiltrosEventos(), ahora: ahora);
    expect(ids(sin), ['a', 'd', 'b', 'c']);
    final conPref = aplicarFiltros(todos, const FiltrosEventos(),
        ahora: ahora, categoriasPreferidas: {2});
    expect(ids(conPref), ['b', 'a', 'd', 'c']);
  });

  test('copiar y sinAvanzados', () {
    const f = FiltrosEventos(texto: 'jazz', categoriaSlug: 'musica');
    final g = f.copiar(
      fecha: FiltroFecha.hoy,
      precio: FiltroPrecio.gratis,
      localidad: 'Suba',
    );
    expect(g.avanzadosActivos, 3);
    expect(g.hayAlgunoActivo, isTrue);
    final h = g.sinAvanzados();
    expect(h.avanzadosActivos, 0);
    expect(h.texto, 'jazz');
    expect(h.categoriaSlug, 'musica');
    expect(g.copiar(quitarLocalidad: true).localidad, isNull);
    expect(g.copiar(quitarCategoria: true).categoriaSlug, isNull);
    expect(const FiltrosEventos().hayAlgunoActivo, isFalse);
  });

  test('localidadesDe: únicas y en orden alfabético', () {
    expect(localidadesDe(todos), ['Santa Fe', 'Suba']);
  });
}
