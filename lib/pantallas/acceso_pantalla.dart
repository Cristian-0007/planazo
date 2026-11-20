import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errores_auth.dart';
import '../core/legal.dart';
import '../core/limite_intentos.dart';
import '../core/tema.dart';
import '../core/validaciones.dart';
import '../widgets/reglas_clave.dart';
import '../widgets/sello_fecha.dart';
import 'confirmar_correo_pantalla.dart';
import 'politica_datos_pantalla.dart';
import 'recuperar_clave_pantalla.dart';
import 'terminos_pantalla.dart';

/// Registro e inicio de sesión con correo y contraseña.
class AccesoPantalla extends StatefulWidget {
  const AccesoPantalla({super.key});

  @override
  State<AccesoPantalla> createState() => _AccesoPantallaState();
}

class _AccesoPantallaState extends State<AccesoPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  bool _registro = false;
  bool _cargando = false;
  bool _verClave = false;
  bool _acepta = false;
  String? _mensaje;
  bool _mensajeEsError = true;

  /// True cuando el inicio de sesión falló porque el correo no está
  /// confirmado: se ofrece el botón para confirmarlo.
  bool _sinConfirmar = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _cambiarModo(bool registro) {
    setState(() {
      _registro = registro;
      _mensaje = null;
      _sinConfirmar = false;
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registro && !_acepta) {
      setState(() {
        _mensajeEsError = true;
        _mensaje =
            'Para crear tu cuenta debes confirmar que eres mayor de ${DatosLegales.edadMinima} años y aceptar los términos de uso y el tratamiento de tus datos personales.';
      });
      return;
    }

    final correo = _correo.text.trim();

    // Tras varios intentos fallidos se pide esperar (RF-GIA-02).
    if (!_registro) {
      final espera = LimiteIntentos.global.segundosRestantes(correo);
      if (espera > 0) {
        setState(() {
          _mensajeEsError = true;
          _sinConfirmar = false;
          _mensaje =
              'Demasiados intentos fallidos. Espera ${textoEspera(espera)} o recupera tu contraseña.';
        });
        return;
      }
    }

    setState(() {
      _cargando = true;
      _mensaje = null;
      _sinConfirmar = false;
    });

    final auth = Supabase.instance.client.auth;

    try {
      if (_registro) {
        final r = await auth.signUp(
          email: correo,
          password: _clave.text,
          data: {
            'nombre': _nombre.text.trim(),
            'acepta_terminos': true,
            'mayor_de_edad': true,
          },
        );
        // Si el proyecto exige confirmar el correo, no hay sesión todavía:
        // se pide el código que llegó al correo.
        if (r.session == null && mounted) {
          setState(() {
            _registro = false;
          });
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ConfirmarCorreoPantalla(correo: correo),
            ),
          );
        }
      } else {
        await auth.signInWithPassword(email: correo, password: _clave.text);
        LimiteIntentos.global.limpiar(correo);
      }
      // Al iniciar sesión, PuertaSesion cambia de pantalla sola.
    } on AuthException catch (e) {
      if (!_registro && e.code == 'invalid_credentials') {
        final bloqueado = LimiteIntentos.global.registrarFallo(correo);
        if (mounted) {
          final quedan = LimiteIntentos.global.intentosRestantes(correo);
          setState(() {
            _mensajeEsError = true;
            _mensaje = bloqueado
                ? 'Demasiados intentos fallidos. Espera ${textoEspera(LimiteIntentos.global.segundosRestantes(correo))} o recupera tu contraseña.'
                : (quedan <= 2
                    ? '${mensajeAuth(e)} Te quedan $quedan ${quedan == 1 ? 'intento' : 'intentos'}.'
                    : mensajeAuth(e));
          });
        }
      } else if (mounted) {
        setState(() {
          _mensajeEsError = true;
          _sinConfirmar = !_registro && e.code == 'email_not_confirmed';
          _mensaje = mensajeAuth(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mensajeEsError = true;
          _mensaje =
              'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _confirmarCorreo() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmarCorreoPantalla(
          correo: _correo.text.trim(),
          enviarAlAbrir: true,
        ),
      ),
    );
  }

  void _abrirPolitica() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PoliticaDatosPantalla()),
    );
  }

  void _abrirTerminos() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TerminosPantalla()),
    );
  }

  void _olvideClave() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RecuperarClavePantalla(correoInicial: _correo.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelloFecha(fecha: DateTime.now(), grande: true),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Planazo',
                      style: Tipografia.display(49, espaciado: -1.5, altura: 1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Descubre, elige y guarda los mejores planes de tu ciudad.',
                      style: Tipografia.ui(16, color: Paleta.papelMut, altura: 1.4),
                    ),
                    const SizedBox(height: 28),
                    _Selector(registro: _registro, alCambiar: _cambiarModo),
                    const SizedBox(height: 20),
                    if (_registro) ...[
                      TextFormField(
                        controller: _nombre,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: decoracionCampo(
                          etiqueta: 'Nombre',
                          icono: Icons.person_outline,
                        ),
                        validator: validarNombre,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: decoracionCampo(
                        etiqueta: 'Correo electrónico',
                        icono: Icons.mail_outline,
                      ),
                      validator: validarCorreo,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_verClave,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _cargando ? null : _enviar(),
                      decoration: decoracionCampo(
                        etiqueta: 'Contraseña',
                        icono: Icons.lock_outline,
                        sufijo: IconButton(
                          tooltip: _verClave
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(
                            _verClave
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Paleta.papelMut,
                          ),
                          onPressed: () {
                            setState(() {
                              _verClave = !_verClave;
                            });
                          },
                        ),
                      ),
                      // Al registrarse se exigen las reglas de seguridad; al
                      // entrar solo que no esté vacía (cuentas anteriores).
                      validator: (v) => _registro
                          ? validarClaveNueva(v)
                          : ((v == null || v.isEmpty)
                              ? 'Escribe tu contraseña.'
                              : null),
                    ),
                    if (_registro) ...[
                      const SizedBox(height: 10),
                      ReglasClaveWidget(controlador: _clave),
                    ] else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _cargando ? null : _olvideClave,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                    if (_registro) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _acepta,
                        onChanged: _cargando
                            ? null
                            : (v) {
                                setState(() {
                                  _acepta = v ?? false;
                                });
                              },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Soy mayor de ${DatosLegales.edadMinima} años, acepto los términos de uso y el tratamiento de mis datos personales (Ley 1581 de 2012).',
                          style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            TextButton(
                              onPressed: _abrirTerminos,
                              child: const Text('Leer los términos de uso'),
                            ),
                            TextButton(
                              onPressed: _abrirPolitica,
                              child: const Text('Leer la política de datos'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_mensaje != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _mensaje!,
                          style: Tipografia.ui(
                            14,
                            peso: FontWeight.w600,
                            altura: 1.4,
                            color: _mensajeEsError ? Paleta.fucsia : Paleta.menta,
                          ),
                        ),
                      ),
                    ],
                    if (_sinConfirmar)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _cargando ? null : _confirmarCorreo,
                          child: const Text('Confirmar mi correo con un código'),
                        ),
                      ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _cargando ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Paleta.noche,
                              ),
                            )
                          : Text(_registro ? 'Crear cuenta' : 'Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({required this.registro, required this.alCambiar});

  final bool registro;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Paleta.noche2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Paleta.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Opcion(
              texto: 'Iniciar sesión',
              activa: !registro,
              alPresionar: () => alCambiar(false),
            ),
          ),
          Expanded(
            child: _Opcion(
              texto: 'Crear cuenta',
              activa: registro,
              alPresionar: () => alCambiar(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.texto,
    required this.activa,
    required this.alPresionar,
  });

  final String texto;
  final bool activa;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activa,
      child: Material(
        color: activa ? Paleta.amarillo : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: alPresionar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Text(
                texto,
                style: Tipografia.ui(
                  14,
                  peso: FontWeight.w700,
                  color: activa ? Paleta.noche : Paleta.papel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}