import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/ciudad.dart';
import '../modelos/evento.dart';

/// Catálogos pequeños que se eligen en el perfil: categorías y ciudades.
class CatalogoServicio {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Categoria>> categorias() async {
    final filas = await _db.from('categorias').select().order('id');
    return filas.map(Categoria.desdeJson).toList();
  }

  /// Solo ciudades activas: la política RLS ya filtra las demás.
  Future<List<Ciudad>> ciudades() async {
    final filas = await _db
        .from('ciudades')
        .select('id, nombre, latitud, longitud')
        .order('nombre');
    return filas.map(Ciudad.desdeJson).toList();
  }
}
