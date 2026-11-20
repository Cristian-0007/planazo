import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Fila tocable del perfil: icono, título, descripción corta y flecha.
class FilaAjuste extends StatelessWidget {
  const FilaAjuste({
    super.key,
    required this.icono,
    required this.titulo,
    required this.alPresionar,
    this.subtitulo,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Paleta.noche2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.md),
          side: const BorderSide(color: Paleta.borde),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radios.md),
          ),
          onTap: alPresionar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Paleta.noche3,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, size: 20, color: Paleta.amarillo),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: Tipografia.ui(15, peso: FontWeight.w700),
                        ),
                        if (subtitulo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitulo!,
                            style: Tipografia.ui(
                              13,
                              color: Paleta.papelMut,
                              altura: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Paleta.papelMut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
