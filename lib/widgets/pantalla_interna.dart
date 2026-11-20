import 'package:flutter/material.dart';

import '../core/tema.dart';

/// Marco de las pantallas que se abren desde el perfil: barra con flecha
/// de volver y título.
class PantallaInterna extends StatelessWidget {
  const PantallaInterna({
    super.key,
    required this.titulo,
    required this.child,
    this.acciones,
  });

  final String titulo;
  final Widget child;

  /// Botones a la derecha de la barra (opcional).
  final List<Widget>? acciones;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Paleta.noche,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          titulo,
          style: Tipografia.display(22, peso: FontWeight.w600),
        ),
        actions: acciones,
      ),
      body: SafeArea(child: child),
    );
  }
}
