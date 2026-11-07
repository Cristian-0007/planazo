import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/evento.dart';

class CatalogoEventos {
  const CatalogoEventos({required this.eventos, required this.categorias});

  final List<Evento> eventos;
  final List<Categoria> categorias;
}

/// Lee el catálogo de eventos desde Supabase.
///
/// Los lugares y las categorías se piden aparte y se unen aquí, porque son
/// tablas pequeñas y así no dependemos de relaciones sobre la vista.
class EventosServicio {
  SupabaseClient get _db => Supabase.instance.client;

  Future<CatalogoEventos> cargar() async {
    final Future<List<Map<String, dynamic>>> pEventos =
        _db.from('eventos_con_estado').select().order('inicia_en');
    final Future<List<Map<String, dynamic>>> pLugares =
        _db.from('lugares').select();
    final Future<List<Map<String, dynamic>>> pCategorias =
        _db.from('categorias').select().order('id');

    final r = await Future.wait<List<Map<String, dynamic>>>([
      pEventos,
      pLugares,
      pCategorias,
    ]);

    final categorias = r[2].map(Categoria.desdeJson).toList();
    final categoriaPorId = {for (final c in categorias) c.id: c};
    final lugarPorId = {
      for (final l in r[1].map(Lugar.desdeJson)) l.id: l,
    };

    final eventos = r[0].map((fila) {
      return Evento.desdeJson(
        fila,
        lugar: lugarPorId[fila['lugar_id']],
        categoria: categoriaPorId[(fila['categoria_id'] as num).toInt()],
      );
    }).toList();

    return CatalogoEventos(eventos: eventos, categorias: categorias);
  }
}
