import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errores_auth.dart';
import '../core/tema.dart';
import '../core/validaciones.dart';
import '../widgets/campo_clave.dart';
import '../widgets/reglas_clave.dart';

/// Recuperar la contraseña con un código que llega al correo (RF-GIA-03).
///
/// Paso 1: se escribe el correo y Supabase envía un código de 6 dígitos.
/// Paso 2: se escribe el código y la contraseña nueva.
class RecuperarClavePantalla extends StatefulWidget {
  const RecuperarClavePantalla({super.key, this.correoInicial = ''});

  final String correoInicial;

  @override
  State<RecuperarClavePantalla> createState() => _RecuperarClavePantallaState();
}

class _RecuperarClavePantallaState extends State<RecuperarClavePantalla> {
  static const _segundosEspera = 60;

  final _formCorreo = GlobalKey<FormState>();
  final _formClave = GlobalKey<FormState>();
  late final TextEditingController _correo;
  final _codigo = TextEditingController();
  final _clave = TextEditingController();
  final _repetida = TextEditingController();

  Timer? _reloj;
  int _espera = 0;
  int _paso = 0;
  bool _cargando = false;
  bool _codigoVerificado = false;
  String? _mensaje;
  bool _mensajeEsError = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _correo = TextEditingController(text: widget.correoInicial);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _correo.dispose();
    _codigo.dispose();
    _clave.dispose();
    _repetida.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    _reloj?.cancel();
    setState(() {
      _espera = _segundosEspera;
    });
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

  Future<void> _enviarCodigo() async {
    if (_paso == 0 && !_formCorreo.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await _db.auth.resetPasswordForEmail(_correo.text.trim());
      if (!mounted) return;
      _iniciarEspera();
      setState(() {
        _paso = 1;
        _mensajeEsError = false;
        // No se dice si el correo existe, para no revelar qué cuentas hay.
        _mensaje =
            'Si el correo está registrado, te enviamos un código. Revisa también la carpeta de spam.';
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

  Future<void> _cambiarClave() async {
    if (!_formClave.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      // El código solo sirve una vez: si ya se verificó y falló el cambio de
      // contraseña (por ejemplo, sin internet), se reintenta solo el cambio.
      if (!_codigoVerificado) {
        await _db.auth.verifyOTP(
          email: _correo.text.trim(),
          token: _codigo.text.trim(),
          type: OtpType.recovery,
        );
        _codigoVerificado = true;
      }
      await _db.auth.updateUser(UserAttributes(password: _clave.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
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

  void _usarOtroCorreo() {
    _reloj?.cancel();
    setState(() {
      _paso = 0;
      _espera = 0;
      _mensaje = null;
      _codigoVerificado = false;
      _codigo.clear();
      _clave.clear();
      _repetida.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Paleta.noche,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Recuperar contraseña',
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
              child: _paso == 0 ? _pasoCorreo() : _pasoClave(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textoMensaje() {
    final mensaje = _mensaje;
    if (mensaje == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Semantics(
        liveRegion: true,
        child: Text(
          mensaje,
          style: Tipografia.ui(
            14,
            peso: FontWeight.w600,
            altura: 1.4,
            color: _mensajeEsError ? Paleta.fucsia : Paleta.menta,
          ),
        ),
      ),
    );
  }

  Widget _boton(String texto, VoidCallback alPresionar) {
    return FilledButton(
      onPressed: _cargando ? null : alPresionar,
      child: _cargando
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Paleta.noche,
              ),
            )
          : Text(texto),
    );
  }

  Widget _pasoCorreo() {
    return Form(
      key: _formCorreo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escribe el correo de tu cuenta y te enviaremos un código para crear una contraseña nueva.',
            style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _cargando ? null : _enviarCodigo(),
            decoration: decoracionCampo(
              etiqueta: 'Correo electrónico',
              icono: Icons.mail_outline,
            ),
            validator: validarCorreo,
          ),
          _textoMensaje(),
          const SizedBox(height: 22),
          _boton('Enviar código', _enviarCodigo),
        ],
      ),
    );
  }

  Widget _pasoClave() {
    return Form(
      key: _formClave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enviamos un código a ${_correo.text.trim()}. Escríbelo y elige tu contraseña nueva.',
            style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _codigo,
            readOnly: _codigoVerificado,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: 14),
          CampoClave(
            controlador: _clave,
            etiqueta: 'Contraseña nueva',
            validador: validarClaveNueva,
            pistas: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 10),
          ReglasClaveWidget(controlador: _clave),
          const SizedBox(height: 14),
          CampoClave(
            controlador: _repetida,
            etiqueta: 'Repite la contraseña nueva',
            accion: TextInputAction.done,
            alEnviar: _cargando ? null : _cambiarClave,
            validador: (v) =>
                v == _clave.text ? null : 'Las contraseñas no coinciden.',
          ),
          _textoMensaje(),
          const SizedBox(height: 22),
          _boton('Cambiar contraseña', _cambiarClave),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_cargando || _espera > 0 || _codigoVerificado)
                ? null
                : _enviarCodigo,
            child: Text(
              _espera > 0 ? 'Reenviar código en $_espera s' : 'Reenviar código',
            ),
          ),
          TextButton(
            onPressed: _cargando ? null : _usarOtroCorreo,
            child: const Text('Usar otro correo'),
          ),
        ],
      ),
    );
  }
}
