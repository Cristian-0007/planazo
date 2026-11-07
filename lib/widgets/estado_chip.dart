import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Etiqueta de estado del evento, con el color propio de cada estado.
/// El texto siempre acompaña al color, para no depender solo del color.
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  /// 'proximo', 'en_curso', 'sin_cupos', 'cancelado' o 'finalizado'.
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, etiqueta) = switch (estado) {
      'proximo' => (const Color(0x2EFFC93C), Paleta.amarillo, 'Próximo'),
      'en_curso' => (const Color(0x294FE0B0), Paleta.menta, 'En curso'),
      'sin_cupos' => (const Color(0x2EFF8A3D), Paleta.naranja, 'Sin cupos'),
      'cancelado' => (const Color(0x2EF5407E), Paleta.fucsia, 'Cancelado'),
      _ => (const Color(0x387A7299), const Color(0xFFB3ABCF), 'Finalizado'),
    };

    return Semantics(
      label: 'Estado: $etiqueta',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Radios.xs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: Tipografia.ui(
                12,
                peso: FontWeight.w800,
                altura: 1.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
