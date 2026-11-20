import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../servicios/avisos_estado.dart';
import '../servicios/eventos_servicio.dart';
import '../servicios/favoritos_estado.dart';

/// Franja que avisa cuando se muestran datos guardados en el teléfono.
class AvisoSinConexion extends StatelessWidget {
  const AvisoSinConexion({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EventosServicio.usandoCopia,
        FavoritosEstado.instancia,
        AvisosEstado.instancia,
      ]),
      builder: (context, _) {
        final visible = EventosServicio.usandoCopia.value ||
            FavoritosEstado.instancia.desdeCopia ||
            AvisosEstado.instancia.desdeCopia;
        if (!visible) return const SizedBox.shrink();

        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Paleta.noche2,
              borderRadius: BorderRadius.circular(Radios.sm),
              border: Border.all(color: Paleta.naranja),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 18, color: Paleta.naranja),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sin conexión. Mostrando datos guardados.',
                    style: Tipografia.ui(13, color: Paleta.papel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}