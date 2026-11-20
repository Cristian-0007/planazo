import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Chip de selección en forma de píldora. Lo usan los filtros de Explorar
/// y el orden de Favoritos.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({
    super.key,
    required this.etiqueta,
    required this.activo,
    required this.alPresionar,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      child: Material(
        color: activo ? Paleta.amarillo : Paleta.noche2,
        shape: StadiumBorder(
          side: BorderSide(color: activo ? Paleta.amarillo : Paleta.borde),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: alPresionar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  etiqueta,
                  style: Tipografia.ui(
                    13,
                    peso: FontWeight.w600,
                    color: activo ? Paleta.noche : Paleta.papel,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
