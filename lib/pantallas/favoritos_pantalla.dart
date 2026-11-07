import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

/// Marcador de posición: se construye en el siguiente paso.
class FavoritosPantalla extends StatelessWidget {
  const FavoritosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: EstadoVacio(
        icono: Icons.bookmark_border,
        titulo: 'Tus favoritos',
        mensaje: 'Aquí aparecerán los eventos que guardes. Esta pantalla se construye en el siguiente paso.',
      ),
    );
  }
}
