import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';

/// Marcador de posición: se construye en el siguiente paso.
class ProximosPantalla extends StatelessWidget {
  const ProximosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: EstadoVacio(
        icono: Icons.calendar_today_outlined,
        titulo: 'Próximos planes',
        mensaje: 'Aquí verás tus eventos guardados ordenados por fecha. Esta pantalla se construye en el siguiente paso.',
      ),
    );
  }
}
