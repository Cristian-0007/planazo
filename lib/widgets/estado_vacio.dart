import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Pantalla para estados vacíos, errores y secciones que aún no existen.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoBoton,
    this.alPresionar,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Paleta.noche2,
                borderRadius: BorderRadius.circular(Radios.lg),
                border: Border.all(color: Paleta.borde),
              ),
              child: Icon(icono, size: 32, color: Paleta.amarillo),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Tipografia.display(26, espaciado: -0.5, altura: 1.1),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                mensaje,
                textAlign: TextAlign.center,
                style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
              ),
            ),
            if (textoBoton != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: alPresionar,
                style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
                child: Text(textoBoton!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
