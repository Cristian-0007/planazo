import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Campo de contraseña con botón para mostrarla u ocultarla.
class CampoClave extends StatefulWidget {
  const CampoClave({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.validador,
    this.accion = TextInputAction.next,
    this.alEnviar,
    this.soloLectura = false,
    this.pistas,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final String? Function(String?)? validador;
  final TextInputAction accion;
  final VoidCallback? alEnviar;
  final bool soloLectura;
  final Iterable<String>? pistas;

  @override
  State<CampoClave> createState() => _CampoClaveState();
}

class _CampoClaveState extends State<CampoClave> {
  bool _ver = false;

  @override
  Widget build(BuildContext context) {
    final alEnviar = widget.alEnviar;
    return TextFormField(
      controller: widget.controlador,
      obscureText: !_ver,
      readOnly: widget.soloLectura,
      textInputAction: widget.accion,
      autofillHints: widget.pistas,
      onFieldSubmitted: alEnviar == null ? null : (_) => alEnviar(),
      validator: widget.validador,
      decoration: decoracionCampo(
        etiqueta: widget.etiqueta,
        icono: Icons.lock_outline,
        sufijo: IconButton(
          tooltip: _ver ? 'Ocultar contraseña' : 'Mostrar contraseña',
          icon: Icon(
            _ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Paleta.papelMut,
          ),
          onPressed: () {
            setState(() {
              _ver = !_ver;
            });
          },
        ),
      ),
    );
  }
}
