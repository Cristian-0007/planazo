import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../core/validaciones.dart';

/// Lista de reglas de la contraseña que se van marcando mientras se escribe.
class ReglasClaveWidget extends StatelessWidget {
  const ReglasClaveWidget({super.key, required this.controlador});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        final r = evaluarClave(controlador.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Regla(texto: 'Al menos 8 caracteres', cumplida: r.largo),
            _Regla(texto: 'Una letra mayúscula', cumplida: r.mayuscula),
            _Regla(texto: 'Una letra minúscula', cumplida: r.minuscula),
            _Regla(texto: 'Un número', cumplida: r.numero),
          ],
        );
      },
    );
  }
}

class _Regla extends StatelessWidget {
  const _Regla({required this.texto, required this.cumplida});

  final String texto;
  final bool cumplida;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$texto: ${cumplida ? 'cumplida' : 'pendiente'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              cumplida ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: cumplida ? Paleta.menta : Paleta.papelMut,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: Tipografia.ui(
                13,
                peso: FontWeight.w600,
                color: cumplida ? Paleta.menta : Paleta.papelMut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
