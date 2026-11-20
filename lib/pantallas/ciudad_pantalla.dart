import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../modelos/ciudad.dart';
import '../widgets/pantalla_interna.dart';
import '../widgets/selector_ciudad.dart';

/// Elegir la ciudad de interés, a mano o con la ubicación (RF-PU-04).
/// Devuelve la [Ciudad] elegida; quien la abre decide si la guarda.
class CiudadPantalla extends StatelessWidget {
  const CiudadPantalla({super.key, this.seleccionadaId});

  final String? seleccionadaId;

  @override
  Widget build(BuildContext context) {
    return PantallaInterna(
      titulo: 'Tu ciudad',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(
            'Te mostraremos los planes de la ciudad que elijas.',
            style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
          ),
          const SizedBox(height: 18),
          SelectorCiudad(
            seleccionadaId: seleccionadaId,
            alElegir: (Ciudad c) => Navigator.of(context).pop(c),
          ),
        ],
      ),
    );
  }
}
