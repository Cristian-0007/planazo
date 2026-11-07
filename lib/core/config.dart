/// Datos de conexión al proyecto Supabase "Planazo".
///
/// La clave "publishable" está pensada para ir dentro de la app: no da
/// acceso por sí sola, porque lo que cada usuario puede ver o modificar
/// lo controlan las políticas RLS de la base de datos.
/// Nunca pongas aquí la clave "service_role" ni "secret".
class Config {
  const Config._();

  static const supabaseUrl = 'https://zsxnwwdkerbyfsvcgqwa.supabase.co';
  static const supabaseClave = 'sb_publishable_scptyh-NStjZsa-vX4AJ5Q_RCB4pB4N';
}
