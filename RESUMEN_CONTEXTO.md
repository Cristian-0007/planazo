# Planazo - resumen de contexto para continuar

## Situación
- Proyecto: app Flutter + Supabase (`Cristian-0007/planazo`), documento técnico del 11-sep-2026.
- Claude no tiene permiso de escritura en el repo: se trabaja sobre el zip (`planazo-actualizado.zip`, carpeta `planazo-main`) y el usuario sube los cambios a Git.
- En el entorno de Claude no hay Flutter ni Dart: NADA se ha compilado ni ejecutado. Solo se revisó a mano (llaves balanceadas, imports existentes). Antes de subir: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`, y pegar a Claude cualquier error.

## Hecho
### Paso 1: detalle, favoritos y próximos (RF-GE-01, RF-EU-04/05/06)
- `servicios/favoritos_estado.dart` (singleton ChangeNotifier, cambia el estado local solo cuando Supabase confirma), `widgets/boton_favorito.dart`, `widgets/chip_filtro.dart`, `pantallas/detalle_pantalla.dart` (con `abrirDetalle()`), `favoritos_pantalla.dart`, `proximos_pantalla.dart`.

### Paso 2: búsqueda, filtros y personalización (RF-EU-01/02/03)
- `core/filtros.dart`, `servicios/preferencias_servicio.dart`, `widgets/hoja_filtros.dart`, `explorar_pantalla.dart`. Pruebas en `test/filtros_test.dart`.

### Paso 3: contraseña, onboarding, perfil, intereses, consentimientos y ciudad (RF-GIA-03/05, RF-PU-01/02/03/04)
- SQL `supabase/03_perfil_y_consentimientos.sql`. Recuperar contraseña por código (OTP), onboarding, perfil con 4 entradas, ciudad con GPS (`geolocator`). Pruebas en `test/validaciones_test.dart` y `test/geo_test.dart`.

### Paso 4: avisos, derechos del titular, política, confirmación de correo y bloqueo (RF-EU-07, RF-CGD-01, RF-GIA-01/02)
- SQL nuevo `supabase/04_avisos_y_derechos.sql` (hay que ejecutarlo):
  - Amplía el check de `notificaciones.tipo` con `inicio_proximo`.
  - Función RPC `sincronizar_avisos_inicio()` (security definer, solo para `authenticated`): crea un aviso por cada favorito del usuario que empieza en las próximas 24 h, si `notificaciones_activas`. Es idempotente por el índice único (perfil, evento, tipo).
  - Tabla `solicitudes_datos` (tipos: acceso, actualizacion, correccion, eliminacion; estados: recibida, en_proceso, resuelta, rechazada) con RLS: el usuario solo lee y crea (GRANT insert solo en perfil_id, tipo, detalle). Un trigger calcula `responder_antes_de` (10 días hábiles para acceso, 15 para el resto; sin festivos) y limita a 5 solicitudes abiertas. Función `sumar_dias_habiles`.
- Avisos: `modelos/notificacion.dart`, `servicios/avisos_estado.dart` (singleton ChangeNotifier: cargar, sincronizar, marcarLeido, marcarTodosLeidos), `pantallas/avisos_pantalla.dart` (bandeja; al tocar marca leído y abre el detalle del evento). Campana con contador en el encabezado de Explorar. `app/inicio.dart` reinicia y sincroniza los avisos al abrir. `PantallaInterna` ahora acepta `acciones`. `formato.dart`: `haceCuanto`.
- Derechos: `modelos/solicitud_datos.dart` (con `TipoSolicitud`), `servicios/solicitudes_servicio.dart`, `pantallas/derechos_pantalla.dart` (formulario + historial). Se abre desde «Privacidad y avisos».
- Política: `core/legal.dart` (texto BORRADOR y constantes `DatosLegales`; `correoPrivacidad` está vacío a propósito), `pantallas/politica_datos_pantalla.dart`. Enlazada en el registro (botón bajo la casilla de aceptación) y en «Privacidad y avisos».
- Confirmación de correo: `pantallas/confirmar_correo_pantalla.dart` (verifyOTP tipo signup, reenvío con espera de 60 s). Se abre tras registrarse cuando no hay sesión, y desde el login si el error es `email_not_confirmed` (envía código nuevo al abrir). Requiere plantilla "Confirm signup" con `{{ .Token }}` (README).
- Bloqueo: `core/limite_intentos.dart` (`LimiteIntentos.global`, 5 fallos `invalid_credentials` -> 5 min, por correo, en memoria). Es solo una barrera de la app; no protege la API.
- Pruebas nuevas: `test/limite_intentos_test.dart` y `test/avisos_derechos_test.dart`. Sin compilar ni ejecutar.
- README y `faltantes_planazo.txt` actualizados.

## Decisiones y límites
- Búsqueda y filtros están dentro de Explorar; con filtro de precio activo, los eventos con "precio por confirmar" quedan fuera.
- Recuperar contraseña: tras verificar el código el usuario ya tiene sesión; si cierra la pantalla sin cambiar la contraseña, queda dentro de la app.
- Cambiar el correo con "Confirm email" activo se confirma por enlace, que abre la Site URL de Supabase y no la app.
- Los avisos de "inicio próximo" solo se generan cuando la persona abre la app o la bandeja. Para que lleguen solos hace falta pg_cron / Edge Function, que irá junto a las push.
- Las solicitudes de derechos se responden editando `solicitudes_datos` en el panel de Supabase (estado, respuesta, resuelta_en). No hay panel de administración.
- La política de datos es un borrador: debe revisarla el responsable del proyecto.
- Si se registra alguien con un correo que ya existe y "Confirm email" está activo, Supabase no revela que existe y el código nunca llega; la pantalla ofrece reenviar.
- Favoritos, Próximos, Explorar y la bandeja piden el catálogo cada uno (consultas pequeñas); se unificará con la caché offline.

## Pendiente (orden sugerido)
4b. Google/Apple (RF-GIA-02): requiere cliente OAuth en Google Cloud, cuenta Apple Developer, activar los proveedores en Supabase y configurar los redirects. Notificaciones push (RF-EU-07): requiere Firebase (FCM), APNs, tabla de tokens y una Edge Function. Bloqueo del lado del servidor.
5. Offline (RNF-PD-03), pruebas de pantallas, localización ES-CO, monitoreo, CI/CD.
Correcciones técnicas que siguen: sacar URL/clave de Supabase del código (`--dart-define`); unificar nombre de docente en README.
Lista completa con casillas: `faltantes_planazo.txt`.

## Antes de subir el paso 4
1. Ejecutar `supabase/04_avisos_y_derechos.sql` (después del 03). Cambiar la plantilla "Confirm signup" (y activar "Confirm email" si se quiere probar ese flujo).
2. `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`, y pegar a Claude cualquier error.
3. Revisar `lib/core/legal.dart` (responsable, correo, texto).
