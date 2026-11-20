import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce los errores de autenticación de Supabase a mensajes claros.
String mensajeAuth(AuthException e) {
  return switch (e.code) {
    'invalid_credentials' => 'Correo o contraseña incorrectos.',
    'user_already_exists' ||
    'email_exists' =>
      'Ya existe una cuenta con ese correo. Prueba iniciando sesión.',
    'email_not_confirmed' =>
      'Debes confirmar tu correo antes de iniciar sesión.',
    'email_address_invalid' => 'Ese correo no es válido.',
    'weak_password' =>
      'La contraseña es muy débil. Usa 8 o más caracteres, con mayúscula, minúscula y número.',
    'same_password' => 'La nueva contraseña debe ser distinta de la actual.',
    'otp_expired' => 'El código no es válido o ya venció. Pide uno nuevo.',
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' =>
      'Hiciste demasiados intentos. Espera un momento e inténtalo de nuevo.',
    'reauthentication_needed' =>
      'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
    _ => 'No pudimos completar la acción: ${e.message}',
  };
}
