import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errores_auth.dart';
import '../core/tema.dart';
import '../core/validaciones.dart';
import '../widgets/campo_clave.dart';
import '../widgets/pantalla_interna.dart';
import '../widgets/reglas_clave.dart';

/// Cambiar el correo (con confirmación) y la contraseña (RF-PU-02).
/// Antes de cada cambio se pide la contraseña actual.
class SeguridadPantalla extends StatefulWidget {
  const SeguridadPantalla({super.key});

  @override
  State<SeguridadPantalla> createState() => _SeguridadPantallaState();
}

class _SeguridadPantallaState extends State<SeguridadPantalla> {
  final _formCorreo = GlobalKey<FormState>();
  final _formClave = GlobalKey<FormState>();
  final _nuevoCorreo = TextEditingController();
  final _claveParaCorreo = TextEditingController();
  final _claveActual = TextEditingController();
  final _claveNueva = TextEditingController();
  final _claveRepetida = TextEditingController();

  bool _cargandoCorreo = false;
  bool _cargandoClave = false;
  String? _mensajeCorreo;
  bool _mensajeCorreoEsError = true;
  String? _mensajeClave;
  bool _mensajeClaveEsError = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void dispose() {
    _nuevoCorreo.dispose();
    _claveParaCorreo.dispose();
    _claveActual.dispose();
    _claveNueva.dispose();
    _claveRepetida.dispose();
    super.dispose();
  }

  /// Comprueba la contraseña actual iniciando sesión de nuevo con ella.
  Future<void> _verificarClaveActual(String clave) async {
    final correo = _db.auth.currentUser?.email;
    if (correo == null) throw AuthException('No hay una sesión iniciada.');
    await _db.auth.signInWithPassword(email: correo, password: clave);
  }

  String _textoError(AuthException e) {
    if (e.code == 'invalid_credentials') {
      return 'La contraseña actual no es correcta.';
    }
    return mensajeAuth(e);
  }

  Future<void> _cambiarCorreo() async {
    if (!_formCorreo.currentState!.validate()) return;
    setState(() {
      _cargandoCorreo = true;
      _mensajeCorreo = null;
    });
    try {
      await _verificarClaveActual(_claveParaCorreo.text);
      final r = await _db.auth.updateUser(
        UserAttributes(email: _nuevoCorreo.text.trim()),
      );
      if (!mounted) return;
      final pendiente = r.user?.newEmail;
      _claveParaCorreo.clear();
      setState(() {
        _mensajeCorreoEsError = false;
        if (pendiente != null) {
          _mensajeCorreo =
              'Te enviamos un enlace de confirmación para cambiar tu correo a $pendiente. Revisa también tu correo actual: puede pedirte confirmar desde los dos. El cambio se aplica cuando lo confirmes.';
        } else {
          _nuevoCorreo.clear();
          _mensajeCorreo = 'Correo actualizado.';
        }
      });
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _mensajeCorreoEsError = true;
          _mensajeCorreo = _textoError(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mensajeCorreoEsError = true;
          _mensajeCorreo =
              'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoCorreo = false;
        });
      }
    }
  }

  Future<void> _cambiarClave() async {
    if (!_formClave.currentState!.validate()) return;
    setState(() {
      _cargandoClave = true;
      _mensajeClave = null;
    });
    try {
      await _verificarClaveActual(_claveActual.text);
      await _db.auth.updateUser(UserAttributes(password: _claveNueva.text));
      if (!mounted) return;
      _claveActual.clear();
      _claveNueva.clear();
      _claveRepetida.clear();
      setState(() {
        _mensajeClaveEsError = false;
        _mensajeClave = 'Contraseña actualizada.';
      });
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _mensajeClaveEsError = true;
          _mensajeClave = _textoError(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mensajeClaveEsError = true;
          _mensajeClave =
              'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoClave = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final correoActual = _db.auth.currentUser?.email ?? '';

    return PantallaInterna(
      titulo: 'Cuenta y seguridad',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text('Correo', style: Tipografia.display(22, peso: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            correoActual,
            style: Tipografia.ui(14, color: Paleta.papelMut),
          ),
          const SizedBox(height: 14),
          Form(
            key: _formCorreo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nuevoCorreo,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: decoracionCampo(
                    etiqueta: 'Correo nuevo',
                    icono: Icons.mail_outline,
                  ),
                  validator: (v) {
                    final base = validarCorreo(v);
                    if (base != null) return base;
                    if (v!.trim().toLowerCase() == correoActual.toLowerCase()) {
                      return 'Ese ya es tu correo actual.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CampoClave(
                  controlador: _claveParaCorreo,
                  etiqueta: 'Tu contraseña actual',
                  accion: TextInputAction.done,
                  alEnviar: _cargandoCorreo ? null : _cambiarCorreo,
                  validador: (v) => (v == null || v.isEmpty)
                      ? 'Escribe tu contraseña actual.'
                      : null,
                ),
                _Mensaje(texto: _mensajeCorreo, esError: _mensajeCorreoEsError),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: _cargandoCorreo ? null : _cambiarCorreo,
                  child: _cargandoCorreo
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Cambiar correo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 18),
          Text('Contraseña', style: Tipografia.display(22, peso: FontWeight.w600)),
          const SizedBox(height: 14),
          Form(
            key: _formClave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoClave(
                  controlador: _claveActual,
                  etiqueta: 'Contraseña actual',
                  validador: (v) => (v == null || v.isEmpty)
                      ? 'Escribe tu contraseña actual.'
                      : null,
                ),
                const SizedBox(height: 14),
                CampoClave(
                  controlador: _claveNueva,
                  etiqueta: 'Contraseña nueva',
                  pistas: const [AutofillHints.newPassword],
                  validador: (v) {
                    final base = validarClaveNueva(v);
                    if (base != null) return base;
                    if (v == _claveActual.text) {
                      return 'La nueva contraseña debe ser distinta de la actual.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ReglasClaveWidget(controlador: _claveNueva),
                const SizedBox(height: 14),
                CampoClave(
                  controlador: _claveRepetida,
                  etiqueta: 'Repite la contraseña nueva',
                  accion: TextInputAction.done,
                  alEnviar: _cargandoClave ? null : _cambiarClave,
                  validador: (v) => v == _claveNueva.text
                      ? null
                      : 'Las contraseñas no coinciden.',
                ),
                _Mensaje(texto: _mensajeClave, esError: _mensajeClaveEsError),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _cargandoClave ? null : _cambiarClave,
                  child: _cargandoClave
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Paleta.noche,
                          ),
                        )
                      : const Text('Cambiar contraseña'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String? texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final t = texto;
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Semantics(
        liveRegion: true,
        child: Text(
          t,
          style: Tipografia.ui(
            14,
            peso: FontWeight.w600,
            altura: 1.4,
            color: esError ? Paleta.fucsia : Paleta.menta,
          ),
        ),
      ),
    );
  }
}
