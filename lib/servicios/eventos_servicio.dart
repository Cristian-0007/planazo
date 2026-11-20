import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
///
/// Modo offline (RNF-PD-03): cada descarga exitosa se guarda en el teléfono.
/// Si la descarga falla, se usa la última copia guardada y [usandoCopia]
/// pasa a true para que la pantalla avise.
class EventosServicio {
  SupabaseClient get _db => Supabase.instance.client;

  /// True cuando el último catálogo mostrado vino de la copia local.
  static final ValueNotifier<bool> usandoCopia = ValueNotifier<bool>(false);

  static const _claveCopia = 'copia_catalogo_v1';

  Future<CatalogoEventos> cargar() async {
    try {
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

      await _guardarCopia(r[0], r[1], r[2]);
      usandoCopia.value = false;
      return _armar(r[0], r[1], r[2]);
    } catch (e) {
      debugPrint('Error cargando eventos, buscando copia local: $e');
      final copia = await _leerCopia();
      if (copia == null) rethrow;
      usandoCopia.value = true;
      return copia;
    }
  }

  CatalogoEventos _armar(
    List<Map<String, dynamic>> filasEventos,
    List<Map<String, dynamic>> filasLugares,
    List<Map<String, dynamic>> filasCategorias,
  ) {
    final categorias = filasCategorias.map(Categoria.desdeJson).toList();
    final categoriaPorId = {for (final c in categorias) c.id: c};
    final lugarPorId = {
      for (final l in filasLugares.map(Lugar.desdeJson)) l.id: l,
    };

    final eventos = filasEventos.map((fila) {
      return Evento.desdeJson(
        fila,
        lugar: lugarPorId[fila['lugar_id']],
        categoria: categoriaPorId[(fila['categoria_id'] as num).toInt()],
      );
    }).toList();

    return CatalogoEventos(eventos: eventos, categorias: categorias);
  }

  Future<void> _guardarCopia(
    List<Map<String, dynamic>> eventos,
    List<Map<String, dynamic>> lugares,
    List<Map<String, dynamic>> categorias,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _claveCopia,
        jsonEncode({
          'eventos': eventos,
          'lugares': lugares,
          'categorias': categorias,
        }),
      );
    } catch (e) {
      // Si no se puede guardar la copia, la app sigue funcionando normal.
      debugPrint('No se pudo guardar la copia local: $e');
    }
  }

  Future<CatalogoEventos?> _leerCopia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_claveCopia);
      if (texto == null) return null;
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      List<Map<String, dynamic>> filas(String clave) => (mapa[clave] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return _armar(filas('eventos'), filas('lugares'), filas('categorias'));
    } catch (e) {
      debugPrint('No se pudo leer la copia local: $e');
      return null;
    }
  }
}
