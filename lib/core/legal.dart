/// Datos legales que se muestran en la política de tratamiento de datos y en
/// los términos de uso.
///
/// Son un BORRADOR de apoyo para el proyecto de aula: antes de publicar la
/// app, el responsable debe revisarlos (idealmente con asesoría jurídica) y
/// completar el correo.
class DatosLegales {
  const DatosLegales._();

  /// Quién decide sobre el tratamiento de los datos.
  static const responsable = 'Equipo Planazo (proyecto de Aplicaciones Híbridas, UCompensar)';

  /// Correo de contacto para temas de privacidad. Si está vacío, la política
  /// solo menciona el canal dentro de la app («Mis derechos»).
  static const correoPrivacidad = 'jeronimot12345@gmail.com';

  /// Edad mínima para crear una cuenta.
  static const edadMinima = 18;

  /// Fecha de la versión vigente de la política y de los términos.
  static const vigenteDesde = '19 de noviembre de 2026';
}

/// Una sección de un texto legal: título y párrafos.
class SeccionPolitica {
  const SeccionPolitica(this.titulo, this.parrafos);

  final String titulo;
  final List<String> parrafos;
}

/// Texto de la política de tratamiento de datos personales (Ley 1581 de 2012
/// y Decreto 1074 de 2015).
List<SeccionPolitica> seccionesPolitica() {
  final contacto = DatosLegales.correoPrivacidad.isEmpty
      ? 'Puedes ejercerlos desde la app, en Perfil → Privacidad y avisos → Mis derechos.'
      : 'Puedes ejercerlos desde la app, en Perfil → Privacidad y avisos → Mis derechos, o escribiendo a ${DatosLegales.correoPrivacidad}.';

  return [
    const SeccionPolitica('Responsable', [
      'El responsable del tratamiento de tus datos personales es ${DatosLegales.responsable}.',
    ]),
    const SeccionPolitica('Quién puede usar la app', [
      'Planazo es para personas de ${DatosLegales.edadMinima} años o más. No recogemos de forma intencional datos de menores de esa edad.',
    ]),
    const SeccionPolitica('Qué datos tratamos', [
      'Datos de tu cuenta: nombre, correo electrónico y contraseña (la contraseña se guarda cifrada y no la podemos leer).',
      'Datos de tu perfil, si decides darlos: teléfono de contacto, ciudad de interés y categorías que te gustan.',
      'Datos de uso dentro de la app: los eventos que guardas como favoritos y los avisos que te enviamos.',
      'Tu ubicación solo se usa en el momento en que tocas «Usar mi ubicación» para sugerirte una ciudad. No la guardamos.',
      'Para que puedas ver eventos sin conexión, la app guarda en tu teléfono una copia del catálogo de eventos y de tu lista de favoritos. Esa copia queda solo en tu dispositivo.',
    ]),
    const SeccionPolitica('Para qué los usamos', [
      'Crear y mantener tu cuenta, y permitirte iniciar sesión.',
      'Mostrarte eventos de tu ciudad y ordenarlos según tus intereses, si dejas activada la personalización.',
      'Avisarte dentro de la app cuando un evento que guardaste se cancela, se queda sin cupos o está por empezar, si dejas activados los avisos.',
      'Atender tus solicitudes sobre tus datos personales.',
    ]),
    SeccionPolitica('Tus derechos como titular', [
      'La Ley 1581 de 2012 te da derecho a conocer, actualizar y rectificar tus datos; a pedir prueba de la autorización que diste; a que te informemos cómo los usamos; a presentar quejas ante la Superintendencia de Industria y Comercio; a revocar la autorización y pedir que borremos tus datos; y a acceder a ellos de forma gratuita.',
      contacto,
      'Respondemos las consultas en máximo 10 días hábiles y los reclamos (actualizar, corregir o eliminar) en máximo 15 días hábiles.',
    ]),
    const SeccionPolitica('Con quién los compartimos', [
      'No vendemos tus datos. Usamos Supabase como proveedor de la base de datos y del inicio de sesión; ese proveedor los procesa por encargo nuestro y bajo medidas de seguridad.',
    ]),
    const SeccionPolitica('Cómo los protegemos', [
      'La conexión con el servidor va cifrada y cada persona solo puede ver y modificar su propia información.',
    ]),
    const SeccionPolitica('Cuánto tiempo los guardamos', [
      'Guardamos tus datos mientras tengas una cuenta. Si pides su eliminación, los borramos, salvo que una norma nos obligue a conservarlos.',
    ]),
    const SeccionPolitica('Cambios a esta política', [
      'Si la cambiamos, publicaremos la nueva versión en la app. Versión vigente desde el ${DatosLegales.vigenteDesde}.',
    ]),
  ];
}

/// Texto de los términos de uso.
List<SeccionPolitica> seccionesTerminos() {
  return [
    const SeccionPolitica('Aceptación', [
      'Al crear una cuenta en Planazo aceptas estos términos y la política de tratamiento de datos personales.',
      'Para usar la app debes tener ${DatosLegales.edadMinima} años o más.',
    ]),
    const SeccionPolitica('Qué es Planazo', [
      'Planazo es una app que reúne información sobre eventos y planes en Bogotá para que los descubras, los guardes y te enteres de cambios.',
      'Planazo es un proyecto académico de ${DatosLegales.responsable}. No organizamos los eventos ni vendemos entradas.',
    ]),
    const SeccionPolitica('Información de los eventos', [
      'Procuramos que fechas, lugares, precios y estados sean correctos, pero pueden cambiar sin aviso. Antes de ir, confirma los datos con el organizador.',
      'Cuando un dato no está confirmado, la app lo indica (por ejemplo, «precio por confirmar»).',
    ]),
    const SeccionPolitica('Tu cuenta', [
      'Eres responsable de guardar tu contraseña y de lo que se haga con tu cuenta. Entrega datos verdaderos y no uses la cuenta de otra persona.',
      'Puedes pedir la eliminación de tu cuenta y de tus datos desde Perfil → Privacidad y avisos → Mis derechos.',
    ]),
    const SeccionPolitica('Uso adecuado', [
      'No uses la app para dañarla, intentar acceder a datos de otras personas, ni para actividades ilegales.',
      'Podemos suspender cuentas que incumplan estos términos.',
    ]),
    const SeccionPolitica('Responsabilidad', [
      'La app se ofrece «tal como está». No nos hacemos responsables por cambios, cancelaciones o hechos ocurridos en los eventos, ni por interrupciones del servicio.',
    ]),
    const SeccionPolitica('Cambios a estos términos', [
      'Si los cambiamos, publicaremos la nueva versión en la app. Versión vigente desde el ${DatosLegales.vigenteDesde}.',
    ]),
  ];
}