import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errores_auth.dart';
import '../core/tema.dart';
import '../core/validaciones.dart';

/// Confirmar el correo al crear la cuenta, con un código de 6 dígitos
/// (RF-GIA-01). Solo aparece cuando el proyecto de Supabase tiene activada la
/// opción «Confirm email».
///
/// Al verificar el código, Supabase abre la sesión y la puerta de sesión
/// cambia sola a la app.
class ConfirmarCorreoPantalla extends StatefulWidget {
  const ConfirmarCorreoPantalla({
    super.key,
    required this.correo,
    this.enviarAlAbrir = false,
  });

  final String correo;

  /// True cuando la persona llega desde un inicio de sesión rechazado por
  /// correo sin confirmar: se le manda un código nuevo al abrir.
  final bool enviarAlAbrir;

  @override
  State<ConfirmarCorreoPantalla> createState() =>
      _ConfirmarCorreoPantallaState();
}

class _ConfirmarCorreoPantallaState extends State<ConfirmarCorreoPantalla> {
  static const _segundosEspera = 60;

  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  Timer? _reloj;
  int _espera = 0;
  bool _cargando = false;
  String? _mensaje;
  bool _mensajeEsError = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.enviarAlAbrir) {
      // Se espera al primer cuadro para poder usar setState sin problema.
      WidgetsBinding.instance.addPostFrameCallback((_) => _reenviar());
    } else {
      // El registro ya mandó el primer código: se cuenta la espera.
      _iniciarEspera();
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _codigo.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    _reloj?.cancel();
    _espera = _segundosEspera;
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _espera--;
      });
      if (_espera <= 0) t.cancel();
    });
  }

  void _error(String texto) {
    setState(() {
      _mensajeEsError = true;
      _mensaje = texto;
    });
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await _db.auth.verifyOTP(
        email: widget.correo,
        token: _codigo.text.trim(),
        type: OtpType.signup,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo confirmado. ¡Bienvenido!')),
      );
      // La sesión ya existe: al volver a la raíz se ve la app.
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on AuthException catch (e) {
      if (mounted) _error(mensajeAuth(e));
    } catch (_) {
      if (mounted) {
        _error('No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await _db.auth.resend(type: OtpType.signup, email: widget.correo);
      if (!mounted) return;
      _iniciarEspera();
      setState(() {
        _mensajeEsError = false;
        _mensaje =
            'Te enviamos un código nuevo. Revisa también la carpeta de spam.';
      });
    } on AuthException catch (e) {
      if (mounted) _error(mensajeAuth(e));
    } catch (_) {
      if (mounted) {
        _error('No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Paleta.noche,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Confirma tu correo',
          style: Tipografia.display(22, peso: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enviamos un código a ${widget.correo}. Escríbelo para activar tu cuenta.',
                      style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _codigo,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _cargando ? null : _verificar(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: decoracionCampo(
                        etiqueta: 'Código de verificación',
                        icono: Icons.pin_outlined,
                      ),
                      validator: validarCodigo,
                    ),
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
                      onPressed: _cargando ? null : _verificar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Paleta.noche,
                              ),
                            )
                          : const Text('Confirmar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: (_cargando || _espera > 0) ? null : _reenviar,
                      child: Text(
                        _espera > 0
                            ? 'Reenviar código en $_espera s'
                            : 'Reenviar código',
                      ),
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
