# Planazo

App móvil híbrida para **descubrir, elegir y guardar planes** en Bogotá.

## Datos del proyecto

- **Materia:** Aplicaciones Híbridas
- **Universidad:** UCompensar
- **Docente:** Andres Felipe Vallejo Sastoque
- **Periodo:** 2026-2

## Integrantes

- Cristian David Galindo Yanquen
- Luis Jeronimo Tapias Figueroa
- Carlos Andres Peña Peña

## Tecnologías

- **Flutter / Dart**: un solo código para Android, iOS y web.
- **Supabase**: autenticación, base de datos PostgreSQL y seguridad por fila (RLS).
- **google_fonts**: Bricolage Grotesque (títulos) y Manrope (interfaz), según el kit de diseño.
- **geolocator**: ubicación aproximada, solo para sugerir la ciudad.

## Estado del prototipo

Funciona:

- Registro e inicio de sesión con correo y contraseña, con aceptación del tratamiento de datos. Las contraseñas nuevas deben tener 8 o más caracteres, mayúscula, minúscula y número.
- **Recuperar contraseña** con un código de 6 dígitos que llega al correo.
- **Onboarding** en el primer arranque: tres pantallas de bienvenida y dos pasos para elegir intereses y ciudad (se puede omitir).
- La sesión se conserva al cerrar y volver a abrir la app.
- **Explorar**: lista de eventos reales desde Supabase, con búsqueda por texto en tiempo real, filtro por categoría y hoja de filtros combinables (fecha, precio y localidad). Se ordena según las categorías de interés del perfil.
- Estados del evento (próximo, en curso, sin cupos, cancelado, finalizado), calculados por la base de datos.
- **Detalle del evento**: fecha, hora, lugar, precio, edad, estado y descripción.
- **Favoritos**: guardar y quitar desde la fila o el detalle; pantalla con orden por fecha.
- **Próximos**: agenda de los favoritos de los próximos 30 días, agrupada por día.
- **Perfil**: datos personales (nombre, teléfono, ciudad), mis intereses, privacidad y avisos (tratamiento de datos, avisos de eventos guardados, personalización), cuenta y seguridad (cambiar correo y contraseña) y cierre de sesión.
- **Ciudad**: se elige a mano o con la ubicación del teléfono (se usa una sola vez y no se guarda). Se ve en el encabezado de Explorar y se cambia tocándola.
- **Avisos**: campana en Explorar con contador y bandeja. Avisan cuando un evento guardado se cancela, se queda sin cupos o empieza en las próximas 24 horas (los dos primeros los crea un trigger; el de inicio próximo se crea al abrir la app o la bandeja).
- **Confirmar correo** con un código de 6 dígitos al crear la cuenta (si _Confirm email_ está activo), con reenvío y espera de 60 s.
- **Bloqueo temporal** tras 5 intentos fallidos de inicio de sesión (5 minutos, solo dentro de la app).
- **Política de tratamiento de datos**, enlazada en el registro y en «Privacidad y avisos» (texto borrador, ver `lib/core/legal.dart`).
- **Mis derechos**: solicitudes para conocer, actualizar, corregir o eliminar datos personales, con fecha límite de respuesta (10 días hábiles para consultas y 15 para reclamos).

Pendiente: Google/Apple, notificaciones push, modo offline, pruebas de pantallas, CI/CD. Ver `faltantes_planazo.txt`.

## Cómo ejecutarlo

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sin errores en Android toolchain).

```
flutter pub get
flutter run -d edge
```

Para Android, abre un emulador o conecta un celular con depuración USB y usa `flutter run`.
En Windows hay que activar el **Modo para desarrolladores** para compilar con plugins.

La app ya apunta a un proyecto de Supabase (`lib/core/config.dart`). Si ese proyecto no está disponible, usa el tuyo:

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. En el **SQL Editor** ejecuta, en orden, `supabase/01_esquema.sql`, `supabase/02_datos_ejemplo.sql`, `supabase/03_perfil_y_consentimientos.sql` y `supabase/04_avisos_y_derechos.sql`. **Sin el 03, las pantallas de perfil, intereses y privacidad no cargan. Sin el 04, no funcionan la bandeja de avisos ni «Mis derechos».**
3. En **Authentication → Sign In / Providers → Email** puedes dejar _Confirm email_ desactivado para pruebas. Si lo activas, la app pide el código de confirmación al crear la cuenta (paso siguiente).
4. En **Authentication → Email Templates** cambia estas dos plantillas para que el correo lleve el código y no un enlace:
   - **Reset Password**:
     ```html
     <h2>Restablecer tu contraseña de Planazo</h2>
     <p>Tu código de verificación es:</p>
     <h1>{{ .Token }}</h1>
     <p>Si no lo pediste, ignora este correo.</p>
     ```
   - **Confirm signup**:
     ```html
     <h2>Confirma tu correo en Planazo</h2>
     <p>Tu código de verificación es:</p>
     <h1>{{ .Token }}</h1>
     <p>Si no creaste una cuenta, ignora este correo.</p>
     ```
5. Pon la URL y la clave _publishable_ de tu proyecto en `lib/core/config.dart`.

Notas sobre el correo: con _Confirm email_ activo, el cambio de correo desde la app envía un enlace de confirmación (por defecto a los dos correos). Ese enlace abre la **Site URL** de Supabase, no la app. Para exigir la misma regla de contraseñas en el servidor, ajusta la longitud mínima en **Authentication → Sign In / Providers → Email**.

## Estructura

```
lib/
  main.dart          arranque y conexión a Supabase
  core/              configuración, tema, formatos, filtros, validaciones, errores de acceso, distancias,
                     límite de intentos y texto legal
  modelos/           Evento, Lugar, Categoria, Ciudad, Perfil, Notificacion, SolicitudDatos
  servicios/         eventos, favoritos, avisos, preferencias, perfil, catálogo, ubicación y solicitudes
  app/               puerta de sesión (con onboarding) y barra de 4 pestañas
  widgets/           sello de fecha, chips, hoja de filtros, fila de evento, botón de favorito, estado vacío,
                     selectores de categorías y ciudad, campo y reglas de contraseña, fila de ajuste
  pantallas/         acceso, confirmar correo, recuperar contraseña, onboarding, explorar, detalle, favoritos,
                     próximos, avisos, perfil, datos personales, intereses, ciudad, privacidad, derechos,
                     política de datos, seguridad
supabase/
  01_esquema.sql         tablas, vista de estados, triggers y políticas RLS
  02_datos_ejemplo.sql   lugares y eventos de ejemplo en Bogotá
  03_perfil_y_consentimientos.sql   teléfono, consentimientos y coordenadas de las ciudades
  04_avisos_y_derechos.sql          avisos de inicio próximo y solicitudes de derechos del titular
```

## Seguridad

La app solo usa la clave _publishable_ de Supabase, que está pensada para ir en el cliente.
Lo que cada usuario puede ver o modificar lo controlan las políticas RLS de la base de datos:
cada persona solo accede a su perfil, sus favoritos y sus avisos.
Nunca se debe poner en la app la clave `service_role` ni la `secret`.
