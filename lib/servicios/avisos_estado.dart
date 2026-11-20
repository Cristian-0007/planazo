import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/notificacion.dart';

/// Guarda en memoria los avisos del usuario (tabla `notificaciones`) y cuántos
/// no ha leído, para que la campana de Explorar y la bandeja se mantengan
/// sincronizadas (RF-EU-07).
///
/// Los avisos de cancelación y de "sin cupos" los crea un trigger de la base
/// de datos. Los de "inicio próximo" se crean al llamar a
/// `sincronizar_avisos_inicio`, que se hace al abrir la app y al abrir la
/// bandeja. La base de datos aplica RLS: cada persona solo ve los suyos.
///
/// Modo offline (RNF-PD-03): la última lista leída con éxito se guarda en el
/// teléfono (una copia por usuario) y se usa si la lectura falla;
/// [desdeCopia] pasa a true para que la pantalla avise. Sin conexión no se
/// pueden marcar avisos como leídos ni sincronizar los de "inicio próximo".
class AvisosEstado extends ChangeNotifier {
  AvisosEstado._();

  static final AvisosEstado instancia = AvisosEstado._();

  List<Notificacion> _avisos = const [];
  bool _cargado = false;
  Object? _error;
  bool _desdeCopia = false;

  List<Notificacion> get avisos => _avisos;

  /// True cuando los avisos ya se leyeron al menos una vez.
  bool get cargado => _cargado;

  /// True si la última lectura falló y no había copia local.
  bool get hayError => _error != null;

  /// True si los avisos mostrados vienen de la copia local.
  bool get desdeCopia => _desdeCopia;

  int get noLeidos => _avisos.where((a) => !a.leida).length;

  SupabaseClient get _db => Supabase.instance.client;

  String get _claveCopia =>
      'copia_avisos_${_db.auth.currentUser?.id ?? 'anon'}';

  /// Olvida lo cargado. Se usa al abrir la app con otra sesión.
  void reiniciar() {
    _avisos = const [];
    _cargado = false;
    _error = null;
    _desdeCopia = false;
  }

  Future<void> cargar() async {
    try {
      final filas = await _db
          .from('notificaciones')
          .select('id, evento_id, tipo, mensaje, creada_en, leida')
          .order('creada_en', ascending: false)
          .limit(100);
      _avisos = filas.map(Notificacion.desdeJson).toList();
      _cargado = true;
      _error = null;
      _desdeCopia = false;
      await _guardarCopia(filas);
    } catch (e) {
      debugPrint('Error cargando avisos, buscando copia local: $e');
      final copia = await _leerCopia();
      if (copia != null) {
        _avisos = copia;
        _cargado = true;
        _error = null;
        _desdeCopia = true;
      } else {
        _error = e;
      }
    }
    notifyListeners();
  }

  /// Crea los avisos de "inicio próximo" que falten y vuelve a leer todo.
  /// Si la sincronización falla, igual se leen los avisos que ya existen (o
  /// la copia local, dentro de [cargar]).
  Future<void> sincronizar() async {
    try {
      await _db.rpc<dynamic>('sincronizar_avisos_inicio');
    } catch (e) {
      debugPrint('Error sincronizando avisos de inicio: $e');
    }
    await cargar();
  }

  /// Devuelve false si no se pudo guardar. El estado local solo cambia
  /// después de que la base de datos confirma.
  Future<bool> marcarLeido(String id) async {
    final indice = _avisos.indexWhere((a) => a.id == id);
    if (indice < 0 || _avisos[indice].leida) return true;
    try {
      await _db.from('notificaciones').update({'leida': true}).eq('id', id);
      _avisos = [..._avisos]..[indice] = _avisos[indice].marcadaLeida();
      await _guardarCopia(_avisosAJson());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marcando aviso como leído: $e');
      return false;
    }
  }

  Future<bool> marcarTodosLeidos() async {
    final perfilId = _db.auth.currentUser?.id;
    if (perfilId == null) return false;
    try {
      await _db
          .from('notificaciones')
          .update({'leida': true})
          .eq('perfil_id', perfilId)
          .eq('leida', false);
      _avisos = [for (final a in _avisos) a.leida ? a : a.marcadaLeida()];
      await _guardarCopia(_avisosAJson());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marcando los avisos como leídos: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _avisosAJson() {
    return _avisos
        .map((a) => {
              'id': a.id,
              'evento_id': a.eventoId,
              'tipo': a.tipo,
              'mensaje': a.mensaje,
              'creada_en': a.creadaEn.toIso8601String(),
              'leida': a.leida,
            })
        .toList();
  }

  Future<void> _guardarCopia(List<Map<String, dynamic>> filas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveCopia, jsonEncode(filas));
    } catch (e) {
      // Si no se puede guardar la copia, la app sigue funcionando normal.
      debugPrint('No se pudo guardar la copia de avisos: $e');
    }
  }

  Future<List<Notificacion>?> _leerCopia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_claveCopia);
      if (texto == null) return null;
      final filas = (jsonDecode(texto) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return filas.map(Notificacion.desdeJson).toList();
    } catch (e) {
      debugPrint('No se pudo leer la copia de avisos: $e');
      return null;
    }
  }
}
