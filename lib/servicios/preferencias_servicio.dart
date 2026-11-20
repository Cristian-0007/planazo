import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lo que el usuario eligió en su perfil y sirve para personalizar Explorar.
class Preferencias {
  const Preferencias({
    this.categoriaIds = const {},
    this.ciudadId,
    this.ciudadNombre,
  });

  /// Categorías de interés (tabla `perfil_categorias`).
  final Set<int> categoriaIds;

  /// Ciudad de interés. null = el usuario aún no eligió una.
  final String? ciudadId;
  final String? ciudadNombre;

  bool get tieneCategorias => categoriaIds.isNotEmpty;

  static const vacias = Preferencias();
}

class _AvisoPreferencias extends ChangeNotifier {
  void avisar() => notifyListeners();
}

/// Lee las preferencias del perfil (RF-PU-03 y RF-PU-04) para ordenar y
/// acotar el catálogo (RF-EU-01).
///
/// Son opcionales: si algo falla, Explorar sigue funcionando con el catálogo
/// completo, por eso aquí los errores no se propagan.
class PreferenciasServicio {
  static final _aviso = _AvisoPreferencias();

  /// Se dispara cuando el usuario cambia sus categorías, su ciudad o sus
  /// consentimientos. Explorar lo escucha para recargarse.
  static Listenable get cambios => _aviso;

  static void avisarCambio() => _aviso.avisar();

  SupabaseClient get _db => Supabase.instance.client;

  Future<Preferencias> cargar() async {
    final id = _db.auth.currentUser?.id;
    if (id == null) return Preferencias.vacias;

    try {
      final perfil = await _db
          .from('perfiles')
          .select('ciudad_id, personalizacion_activa')
          .eq('id', id)
          .maybeSingle();

      // Si la persona apagó la personalización, no se usan sus categorías.
      final personalizar = perfil?['personalizacion_activa'] != false;
      final filas = personalizar
          ? await _db
              .from('perfil_categorias')
              .select('categoria_id')
              .eq('perfil_id', id)
          : const <Map<String, dynamic>>[];

      final ciudadId = perfil?['ciudad_id'] as String?;
      String? ciudadNombre;
      if (ciudadId != null) {
        final ciudad = await _db
            .from('ciudades')
            .select('nombre')
            .eq('id', ciudadId)
            .maybeSingle();
        ciudadNombre = ciudad?['nombre'] as String?;
      }

      return Preferencias(
        categoriaIds: {
          for (final f in filas) (f['categoria_id'] as num).toInt(),
        },
        ciudadId: ciudadId,
        ciudadNombre: ciudadNombre,
      );
    } catch (e) {
      debugPrint('Error cargando preferencias: $e');
      return Preferencias.vacias;
    }
  }
}
