import 'package:flutter/material.dart';

import '../core/legal.dart';
import '../core/tema.dart';
import '../widgets/pantalla_interna.dart';

/// Términos de uso. Se abre desde el registro.
class TerminosPantalla extends StatelessWidget {
  const TerminosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final secciones = seccionesTerminos();

    return PantallaInterna(
      titulo: 'Términos de uso',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(
            'Términos de uso de Planazo',
            style: Tipografia.display(26, espaciado: -0.4, altura: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            'Versión vigente desde el ${DatosLegales.vigenteDesde}',
            style: Tipografia.ui(13, color: Paleta.papelMut),
          ),
          for (final s in secciones) ...[
            const SizedBox(height: 22),
            Semantics(
              header: true,
              child: Text(
                s.titulo,
                style: Tipografia.ui(16, peso: FontWeight.w800, color: Paleta.amarillo),
              ),
            ),
            for (final p in s.parrafos) ...[
              const SizedBox(height: 8),
              Text(p, style: Tipografia.ui(14, altura: 1.5)),
            ],
          ],
        ],
      ),
    );
  }
}