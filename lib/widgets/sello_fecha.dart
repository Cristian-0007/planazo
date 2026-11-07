import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';

/// El "sello de fecha": elemento firma de Planazo.
class SelloFecha extends StatelessWidget {
  const SelloFecha({super.key, required this.fecha, this.grande = false});

  final DateTime fecha;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final lado = grande ? 76.0 : 46.0;

    final sello = Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: Paleta.amarillo,
        borderRadius: BorderRadius.circular(Radios.xs),
        boxShadow: grande
            ? const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${fecha.day}',
            style: Tipografia.display(
              grande ? 34 : 21,
              espaciado: grande ? -1 : -0.6,
              altura: 1,
              color: Paleta.noche,
            ),
          ),
          SizedBox(height: grande ? 3 : 2),
          Text(
            mesCorto(fecha).toUpperCase(),
            style: Tipografia.ui(
              grande ? 12 : 11,
              peso: FontWeight.w700,
              altura: 1,
              color: Paleta.noche,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'Fecha: ${fecha.day} de ${mesCorto(fecha)}',
      excludeSemantics: true,
      child: grande ? Transform.rotate(angle: -0.07, child: sello) : sello,
    );
  }
}
