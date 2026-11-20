import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/perfil.dart';
import 'preferencias_servicio.dart';

/// Lee y guarda el perfil del usuario en Supabase (RF-PU-01, RF-PU-03,
/// RF-PU-04 y RF-GIA-05). La base de datos aplica RLS: cada persona solo
/// toca su propia fila, y solo las columnas que se le permiten editar.
class PerfilServicio {
  SupabaseClient get _db => Supabase.instance.client;

  String get _id {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw StateError('No hay una sesión iniciada.');
    return id;
  }

  Future<Perfil?> cargar() async {
    final id = _db.auth.currentUser?.id;
    if (id == null) return null;
    final fila = await _db
        .from('perfiles')
        .select(
          'nombre, telefono, ciudad_id, onboarding_completo, acepta_terminos, '
          'acepto_en, notificaciones_activas, personalizacion_activa, '
          'ciudades(nombre)',
        )
        .eq('id', id)
        .maybeSingle();
    return fila == null ? null : Perfil.desdeJson(fila);
  }

  /// Solo lee la bandera del onboarding. Si el perfil no existe devuelve true
  /// para no bloquear la app.
  Future<bool> onboardingCompleto() async {
    final fila = await _db
        .from('perfiles')
        .select('onboarding_completo')
        .eq('id', _id)
        .maybeSingle();
    if (fila == null) return true;
    return fila['onboarding_completo'] == true;
  }

  Future<void> guardarDatos({
    required String nombre,
    String? telefono,
    String? ciudadId,
  }) async {
    await _db.from('perfiles').update({
      'nombre': nombre.trim(),
      'telefono': telefono,
      'ciudad_id': ciudadId,
    }).eq('id', _id);
    PreferenciasServicio.avisarCambio();
  }

  Future<void> guardarCiudad(String ciudadId) async {
    await _db.from('perfiles').update({'ciudad_id': ciudadId}).eq('id', _id);
    PreferenciasServicio.avisarCambio();
  }

  Future<Set<int>> categoriasDelPerfil() async {
    final filas = await _db
        .from('perfil_categorias')
        .select('categoria_id')
        .eq('perfil_id', _id);
    return {for (final f in filas) (f['categoria_id'] as num).toInt()};
  }

  /// Deja guardadas exactamente las categorías indicadas: quita las que ya
  /// no están y agrega las nuevas.
  Future<void> guardarCategorias(Set<int> nuevas) async {
    final id = _id;
    final actuales = await categoriasDelPerfil();
    final quitar = actuales.difference(nuevas);
    final agregar = nuevas.difference(actuales);

    if (quitar.isNotEmpty) {
      await _db
          .from('perfil_categorias')
          .delete()
          .eq('perfil_id', id)
          .inFilter('categoria_id', quitar.toList());
    }
    if (agregar.isNotEmpty) {
      await _db.from('perfil_categorias').insert([
        for (final c in agregar) {'perfil_id': id, 'categoria_id': c},
      ]);
    }
    PreferenciasServicio.avisarCambio();
  }

  /// Cambia solo las preferencias que se indiquen.
  Future<void> guardarConsentimientos({
    bool? notificaciones,
    bool? personalizacion,
  }) async {
    final cambios = <String, Object>{
      if (notificaciones != null) 'notificaciones_activas': notificaciones,
      if (personalizacion != null) 'personalizacion_activa': personalizacion,
    };
    if (cambios.isEmpty) return;
    await _db.from('perfiles').update(cambios).eq('id', _id);
    PreferenciasServicio.avisarCambio();
  }

  /// Termina el onboarding. La bandera se guarda al final: si algo falla
  /// antes, el onboarding vuelve a aparecer y se puede reintentar.
  Future<void> completarOnboarding({
    Set<int> categorias = const {},
    String? ciudadId,
  }) async {
    if (categorias.isNotEmpty) {
      await guardarCategorias(categorias);
    }
    await _db.from('perfiles').update({
      'onboarding_completo': true,
      if (ciudadId != null) 'ciudad_id': ciudadId,
    }).eq('id', _id);
    PreferenciasServicio.avisarCambio();
  }
}
