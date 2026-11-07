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

## Estado del prototipo

Funciona:

- Registro e inicio de sesión con correo y contraseña, con aceptación del tratamiento de datos.
- La sesión se conserva al cerrar y volver a abrir la app.
- **Explorar**: lista de eventos reales leídos desde Supabase, con filtro por categoría.
- Estados del evento (próximo, en curso, sin cupos, cancelado, finalizado), calculados por la base de datos.
- **Perfil** con el nombre del usuario y cierre de sesión.
- Aviso dentro de la app cuando un evento guardado se cancela o se queda sin cupos (trigger en la base de datos).

Pendiente: detalle del evento, favoritos, próximos, búsqueda y filtros avanzados, recuperar contraseña, elegir categorías al registrarse.

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
2. En el **SQL Editor** ejecuta, en orden, `supabase/01_esquema.sql` y `supabase/02_datos_ejemplo.sql`.
3. En **Authentication → Sign In / Providers → Email** desactiva _Confirm email_ para pruebas.
4. Pon la URL y la clave _publishable_ de tu proyecto en `lib/core/config.dart`.

## Estructura

```
lib/
  main.dart          arranque y conexión a Supabase
  core/              configuración, tema (colores y fuentes del kit), formatos
  modelos/           Evento, Lugar, Categoria
  servicios/         lectura de eventos desde Supabase
  app/               puerta de sesión y barra de 4 pestañas
  widgets/           sello de fecha, chip de estado, fila de evento, estado vacío
  pantallas/         acceso, explorar, favoritos, próximos, perfil
supabase/
  01_esquema.sql         tablas, vista de estados, triggers y políticas RLS
  02_datos_ejemplo.sql   lugares y eventos de ejemplo en Bogotá
```

## Seguridad

La app solo usa la clave _publishable_ de Supabase, que está pensada para ir en el cliente.
Lo que cada usuario puede ver o modificar lo controlan las políticas RLS de la base de datos:
cada persona solo accede a su perfil, sus favoritos y sus avisos.
Nunca se debe poner en la app la clave `service_role` ni la `secret`.
