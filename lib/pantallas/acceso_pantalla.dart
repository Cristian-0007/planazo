import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/tema.dart';
import '../widgets/sello_fecha.dart';

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
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registro && !_acepta) {
      setState(() {
        _mensajeEsError = true;
        _mensaje =
            'Para crear tu cuenta debes aceptar el tratamiento de tus datos personales.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    final auth = Supabase.instance.client.auth;
    final correo = _correo.text.trim();

    try {
      if (_registro) {
        final r = await auth.signUp(
          email: correo,
          password: _clave.text,
          data: {
            'nombre': _nombre.text.trim(),
            'acepta_terminos': true,
          },
        );
        // Si el proyecto exige confirmar el correo, no hay sesión todavía.
        if (r.session == null && mounted) {
          setState(() {
            _registro = false;
            _mensajeEsError = false;
            _mensaje =
                'Te enviamos un correo para confirmar tu cuenta. Confírmalo y luego inicia sesión.';
          });
        }
      } else {
        await auth.signInWithPassword(email: correo, password: _clave.text);
      }
      // Al iniciar sesión, PuertaSesion cambia de pantalla sola.
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _mensajeEsError = true;
          _mensaje = _traducir(e);
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

  String _traducir(AuthException e) {
    return switch (e.code) {
      'invalid_credentials' => 'Correo o contraseña incorrectos.',
      'user_already_exists' ||
      'email_exists' =>
        'Ya existe una cuenta con ese correo. Prueba iniciando sesión.',
      'email_not_confirmed' =>
        'Debes confirmar tu correo antes de iniciar sesión.',
      'weak_password' =>
        'La contraseña es muy débil. Usa al menos 6 caracteres.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Hiciste demasiados intentos. Espera un momento e inténtalo de nuevo.',
      _ => 'No pudimos completar la acción: ${e.message}',
    };
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
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Escribe tu nombre.'
                            : null,
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
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                            ? null
                            : 'Escribe un correo válido.';
                      },
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
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Usa al menos 6 caracteres.'
                          : null,
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
                          'Acepto el tratamiento de mis datos personales (Ley 1581 de 2012).',
                          style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
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
