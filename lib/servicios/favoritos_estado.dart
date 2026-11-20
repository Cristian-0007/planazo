import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guarda en memoria qué eventos son favoritos del usuario y los mantiene
/// sincronizados con la tabla `favoritos` de Supabase.
///
/// Es un único objeto compartido: así el botón de guardar, la lista de
/// Favoritos y la agenda de Próximos se actualizan juntos sin recargar.
/// La base de datos aplica RLS: cada persona solo lee y escribe los suyos.
///
/// Modo offline: la última lista confirmada se guarda en el teléfono (una
/// por usuario) y se usa si no hay conexión. Sin conexión no se puede
/// agregar ni quitar favoritos.
class FavoritosEstado extends ChangeNotifier {
  FavoritosEstado._();

  static final FavoritosEstado instancia = FavoritosEstado._();

  final Set<String> _ids = {};
  bool _cargado = false;
  Object? _error;
  bool _desdeCopia = false;

  /// True cuando los favoritos ya se leyeron al menos una vez.
  bool get cargado => _cargado;

  /// True si la última lectura falló y no había copia local.
  bool get hayError => _error != null;

  /// True si los favoritos mostrados vienen de la copia local.
  bool get desdeCopia => _desdeCopia;

  Set<String> get ids => Set.unmodifiable(_ids);

  bool esFavorito(String eventoId) => _ids.contains(eventoId);

  SupabaseClient get _db => Supabase.instance.client;

  String get _claveCopia => 'copia_favoritos_${_db.auth.currentUser?.id ?? 'anon'}';

  /// Olvida lo cargado. Se usa al abrir la app con otra sesión.
  void reiniciar() {
    _ids.clear();
    _cargado = false;
    _error = null;
    _desdeCopia = false;
  }

  Future<void> cargar() async {
    try {
      final filas = await _db.from('favoritos').select('evento_id');
      _ids
        ..clear()
        ..addAll(filas.map((f) => f['evento_id'] as String));
      _cargado = true;
      _error = null;
      _desdeCopia = false;
      await _guardarCopia();
    } catch (e) {
      debugPrint('Error cargando favoritos: $e');
      final copia = await _leerCopia();
      if (copia != null) {
        _ids
          ..clear()
          ..addAll(copia);
        _cargado = true;
        _error = null;
        _desdeCopia = true;
      } else {
        _error = e;
      }
    }
    notifyListeners();
  }

  /// Guarda el evento si no era favorito, o lo quita si ya lo era.
  /// Devuelve false si no se pudo completar (sin sesión o sin conexión).
  /// El estado local solo cambia después de que la base de datos confirma.
  Future<bool> alternar(String eventoId) async {
    final perfilId = _db.auth.currentUser?.id;
    if (perfilId == null) return false;

    try {
      if (_ids.contains(eventoId)) {
        await _db
            .from('favoritos')
            .delete()
            .eq('perfil_id', perfilId)
            .eq('evento_id', eventoId);
        _ids.remove(eventoId);
      } else {
        await _db
            .from('favoritos')
            .insert({'perfil_id': perfilId, 'evento_id': eventoId});
        _ids.add(eventoId);
      }
      _desdeCopia = false;
      await _guardarCopia();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error actualizando favorito: $e');
      return false;
    }
  }

  Future<void> _guardarCopia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveCopia, jsonEncode(_ids.toList()));
    } catch (e) {
      debugPrint('No se pudo guardar la copia de favoritos: $e');
    }
  }

  Future<List<String>?> _leerCopia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_claveCopia);
      if (texto == null) return null;
      return (jsonDecode(texto) as List).map((e) => e as String).toList();
    } catch (e) {
      debugPrint('No se pudo leer la copia de favoritos: $e');
      return null;
    }
  }
}
