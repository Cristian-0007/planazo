// Validaciones de formularios. Son funciones sueltas para poder probarlas
// sin abrir ninguna pantalla.

final _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _regexTelefono = RegExp(r'^\+?[0-9]{7,15}$');

String? validarCorreo(String? v) {
  final t = v?.trim() ?? '';
  return _regexCorreo.hasMatch(t) ? null : 'Escribe un correo válido.';
}

String? validarNombre(String? v) {
  final t = v?.trim() ?? '';
  if (t.length < 2) return 'Escribe tu nombre.';
  if (t.length > 80) return 'Usa máximo 80 caracteres.';
  return null;
}

/// Qué reglas de complejidad cumple una contraseña (RF-GIA-03).
class ReglasClave {
  const ReglasClave({
    required this.largo,
    required this.mayuscula,
    required this.minuscula,
    required this.numero,
  });

  final bool largo;
  final bool mayuscula;
  final bool minuscula;
  final bool numero;

  bool get cumple => largo && mayuscula && minuscula && numero;
}

ReglasClave evaluarClave(String clave) {
  return ReglasClave(
    largo: clave.length >= 8,
    mayuscula: RegExp(r'\p{Lu}', unicode: true).hasMatch(clave),
    minuscula: RegExp(r'\p{Ll}', unicode: true).hasMatch(clave),
    numero: RegExp(r'[0-9]').hasMatch(clave),
  );
}

/// Para contraseñas nuevas (registro, recuperación y cambio).
/// Al iniciar sesión no se exige: las cuentas viejas pueden tener otra.
String? validarClaveNueva(String? v) {
  final clave = v ?? '';
  if (clave.isEmpty) return 'Escribe una contraseña.';
  if (clave.length > 72) return 'Usa máximo 72 caracteres.';
  if (!evaluarClave(clave).cumple) {
    return 'La contraseña no cumple las reglas de seguridad.';
  }
  return null;
}

/// Quita espacios, guiones y paréntesis. Devuelve null si queda vacío.
String? normalizarTelefono(String? v) {
  if (v == null) return null;
  final limpio = v.replaceAll(RegExp(r'[\s\-().]'), '');
  return limpio.isEmpty ? null : limpio;
}

/// El teléfono es opcional; si se escribe, debe tener de 7 a 15 dígitos.
String? validarTelefono(String? v) {
  final n = normalizarTelefono(v);
  if (n == null) return null;
  return _regexTelefono.hasMatch(n)
      ? null
      : 'Escribe un teléfono válido (solo números, con o sin +).';
}

/// Código de verificación que llega por correo (6 a 10 dígitos).
String? validarCodigo(String? v) {
  final t = v?.trim() ?? '';
  return RegExp(r'^[0-9]{6,10}$').hasMatch(t)
      ? null
      : 'Escribe el código que llegó a tu correo.';
}
