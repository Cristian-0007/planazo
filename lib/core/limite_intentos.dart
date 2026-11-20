/// Bloqueo temporal tras varios intentos fallidos de inicio de sesión
/// (RF-GIA-02).
///
/// IMPORTANTE: vive solo en la app, en memoria. Frena a quien adivina la
/// contraseña desde la propia pantalla, pero no protege la API de Supabase
/// contra alguien que no use la app (para eso están los límites de peticiones
/// de Supabase y, en planes que lo permiten, los hooks de autenticación).
/// Al cerrar la app el contador se reinicia.
class LimiteIntentos {
  LimiteIntentos({
    this.maxIntentos = 5,
    this.duracionBloqueo = const Duration(minutes: 5),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  /// Contador compartido por toda la app.
  static final LimiteIntentos global = LimiteIntentos();

  final int maxIntentos;
  final Duration duracionBloqueo;
  final DateTime Function() _reloj;

  final Map<String, int> _fallos = {};
  final Map<String, DateTime> _bloqueadoHasta = {};

  String _clave(String correo) => correo.trim().toLowerCase();

  /// Segundos que faltan para poder intentarlo otra vez; 0 si no hay bloqueo.
  int segundosRestantes(String correo) {
    final k = _clave(correo);
    final hasta = _bloqueadoHasta[k];
    if (hasta == null) return 0;
    final falta = hasta.difference(_reloj());
    if (falta.isNegative || falta == Duration.zero) {
      // El bloqueo terminó: se empieza de cero.
      _bloqueadoHasta.remove(k);
      _fallos.remove(k);
      return 0;
    }
    return (falta.inMilliseconds / 1000).ceil();
  }

  bool estaBloqueado(String correo) => segundosRestantes(correo) > 0;

  /// Anota un intento fallido. Devuelve true si con este se activó el bloqueo.
  bool registrarFallo(String correo) {
    final k = _clave(correo);
    final n = (_fallos[k] ?? 0) + 1;
    _fallos[k] = n;
    if (n >= maxIntentos) {
      _bloqueadoHasta[k] = _reloj().add(duracionBloqueo);
      return true;
    }
    return false;
  }

  /// Intentos que quedan antes del bloqueo.
  int intentosRestantes(String correo) {
    final usados = _fallos[_clave(correo)] ?? 0;
    final r = maxIntentos - usados;
    return r < 0 ? 0 : r;
  }

  /// Se llama al iniciar sesión bien.
  void limpiar(String correo) {
    final k = _clave(correo);
    _fallos.remove(k);
    _bloqueadoHasta.remove(k);
  }
}

/// "5 minutos", "1 minuto" o "40 segundos".
String textoEspera(int segundos) {
  if (segundos >= 60) {
    final m = (segundos / 60).ceil();
    return m == 1 ? '1 minuto' : '$m minutos';
  }
  return segundos == 1 ? '1 segundo' : '$segundos segundos';
}
