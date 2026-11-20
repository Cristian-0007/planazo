/// Datos de conexión al proyecto Supabase "Planazo".
///
/// La clave "publishable" está pensada para ir dentro de la app: no da
/// acceso por sí sola, porque lo que cada usuario puede ver o modificar
/// lo controlan las políticas RLS de la base de datos.
/// Nunca pongas aquí la clave "service_role" ni "secret".
class Config {
  const Config._();

  static const supabaseUrl = 'https://witgyjdlxeuabgonjbst.supabase.co';
  static const supabaseClave = 'sb_publishable_NuFPXbaT9sYxaU6aw6PubQ_B8rsUnzd';
}
