import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../modelos/perfil.dart';
import '../servicios/perfil_servicio.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_ajuste.dart';
import '../widgets/pantalla_interna.dart';
import 'derechos_pantalla.dart';
import 'politica_datos_pantalla.dart';
import 'terminos_pantalla.dart';

/// Consentimientos y permisos (RF-PU-03): tratamiento de datos, avisos y
/// personalización. Cada interruptor se guarda en cuanto se mueve.
class PrivacidadPantalla extends StatefulWidget {
  const PrivacidadPantalla({super.key});

  @override
  State<PrivacidadPantalla> createState() => _PrivacidadPantallaState();
}

class _PrivacidadPantallaState extends State<PrivacidadPantalla> {
  final _servicio = PerfilServicio();
  Perfil? _perfil;
  bool _cargando = true;
  bool _error = false;
  bool _guardando = false;

  // Valores que se muestran; pueden adelantarse a la base mientras se guarda.
  bool _notificaciones = true;
  bool _personalizacion = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await _servicio.cargar();
      if (!mounted) return;
      if (perfil == null) throw StateError('No se encontró el perfil.');
      setState(() {
        _perfil = perfil;
        _notificaciones = perfil.notificacionesActivas;
        _personalizacion = perfil.personalizacionActiva;
        _cargando = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Error cargando consentimientos: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = false;
    });
    _cargar();
  }

  Future<void> _cambiar({bool? notificaciones, bool? personalizacion}) async {
    final antesNotificaciones = _notificaciones;
    final antesPersonalizacion = _personalizacion;
    setState(() {
      _guardando = true;
      if (notificaciones != null) _notificaciones = notificaciones;
      if (personalizacion != null) _personalizacion = personalizacion;
    });
    try {
      await _servicio.guardarConsentimientos(
        notificaciones: notificaciones,
        personalizacion: personalizacion,
      );
    } catch (e) {
      debugPrint('Error guardando consentimientos: $e');
      if (!mounted) return;
      setState(() {
        _notificaciones = antesNotificaciones;
        _personalizacion = antesPersonalizacion;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar el cambio. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _abrir(Widget pantalla) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
  }

  String _textoAutorizacion() {
    final perfil = _perfil;
    if (perfil == null || !perfil.aceptaTerminos) {
      return 'No hay una autorización registrada.';
    }
    final f = perfil.aceptoEn;
    if (f == null) return 'Aceptaste el tratamiento de tus datos personales.';
    return 'Aceptaste el tratamiento de tus datos el ${f.day} ${mesCorto(f)} ${f.year}.';
  }

  @override
  Widget build(BuildContext context) {
    return PantallaInterna(
      titulo: 'Privacidad y avisos',
      child: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return EstadoVacio(
        icono: Icons.wifi_off,
        titulo: 'No pudimos cargar tus preferencias',
        mensaje: 'Revisa tu conexión e inténtalo de nuevo.',
        textoBoton: 'Reintentar',
        alPresionar: _reintentar,
      );
    }
    final autorizado = _perfil?.aceptaTerminos == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _Tarjeta(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                autorizado ? Icons.verified_user_outlined : Icons.info_outline,
                color: autorizado ? Paleta.menta : Paleta.papelMut,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tratamiento de datos personales',
                      style: Tipografia.ui(15, peso: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _textoAutorizacion(),
                      style: Tipografia.ui(
                        13,
                        color: Paleta.papelMut,
                        altura: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Tarjeta(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notificaciones,
            onChanged: _guardando
                ? null
                : (v) => _cambiar(notificaciones: v),
            title: Text(
              'Avisos de mis eventos guardados',
              style: Tipografia.ui(15, peso: FontWeight.w700),
            ),
            subtitle: Text(
              'Te avisamos dentro de la app si un evento que guardaste se cancela, se queda sin cupos o empieza pronto.',
              style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Tarjeta(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _personalizacion,
            onChanged: _guardando
                ? null
                : (v) => _cambiar(personalizacion: v),
            title: Text(
              'Personalizar mis planes',
              style: Tipografia.ui(15, peso: FontWeight.w700),
            ),
            subtitle: Text(
              'Usamos tus categorías de interés para mostrarte primero lo que más te gusta. Si lo apagas, Explorar ordena todo por fecha.',
              style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Tarjeta(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, color: Paleta.papelMut),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación',
                      style: Tipografia.ui(15, peso: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo pedimos tu ubicación cuando tocas «Usar mi ubicación» para elegir tu ciudad. No la guardamos: solo guardamos la ciudad que elijas.',
                      style: Tipografia.ui(
                        13,
                        color: Paleta.papelMut,
                        altura: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilaAjuste(
          icono: Icons.description_outlined,
          titulo: 'Política de tratamiento de datos',
          subtitulo: 'Qué datos usamos y para qué',
          alPresionar: () => _abrir(const PoliticaDatosPantalla()),
        ),
        const SizedBox(height: 10),
        FilaAjuste(
          icono: Icons.article_outlined,
          titulo: 'Términos de uso',
          subtitulo: 'Las reglas para usar Planazo',
          alPresionar: () => _abrir(const TerminosPantalla()),
        ),
        const SizedBox(height: 10),
        FilaAjuste(
          icono: Icons.gavel_outlined,
          titulo: 'Mis derechos',
          subtitulo: 'Conocer, actualizar, corregir o eliminar mis datos',
          alPresionar: () => _abrir(const DerechosPantalla()),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Paleta.noche2,
        borderRadius: BorderRadius.circular(Radios.md),
        border: Border.all(color: Paleta.borde),
      ),
      child: child,
    );
  }
}