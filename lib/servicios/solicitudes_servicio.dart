import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/solicitud_datos.dart';

/// Crea y lista las solicitudes de derechos del titular (RF-CGD-01).
/// La base de datos aplica RLS: cada persona solo ve y crea las suyas, y la
/// fecha límite de respuesta la calcula un trigger.
class SolicitudesServicio {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<SolicitudDatos>> listar() async {
    final filas = await _db
        .from('solicitudes_datos')
        .select()
        .order('creada_en', ascending: false);
    return filas.map(SolicitudDatos.desdeJson).toList();
  }

  Future<void> crear({required String tipo, required String detalle}) async {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw StateError('No hay una sesión iniciada.');
    await _db.from('solicitudes_datos').insert({
      'perfil_id': id,
      'tipo': tipo,
      'detalle': detalle.trim(),
    });
  }
}
