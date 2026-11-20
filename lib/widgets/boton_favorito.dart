import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../servicios/favoritos_estado.dart';

/// Marcador para guardar o quitar un evento de favoritos (RF-EU-04).
/// Se usa en la fila de evento y en el detalle.
class BotonFavorito extends StatefulWidget {
  const BotonFavorito({
    super.key,
    required this.eventoId,
    this.sobreImagen = false,
  });

  final String eventoId;

  /// En el detalle el botón va sobre la foto: lleva fondo oscuro translúcido.
  final bool sobreImagen;

  @override
  State<BotonFavorito> createState() => _BotonFavoritoState();
}

class _BotonFavoritoState extends State<BotonFavorito> {
  bool _ocupado = false;

  Future<void> _alternar() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
    });

    final ok = await FavoritosEstado.instancia.alternar(widget.eventoId);

    // Si la fila desapareció de la lista mientras tanto, no hay nada que pintar.
    if (!mounted) return;
    setState(() {
      _ocupado = false;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos actualizar tus favoritos. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritosEstado.instancia,
      builder: (context, _) {
        final guardado = FavoritosEstado.instancia.esFavorito(widget.eventoId);

        return IconButton(
          tooltip: guardado ? 'Quitar de favoritos' : 'Guardar en favoritos',
          onPressed: _ocupado ? null : _alternar,
          style: widget.sobreImagen
              ? IconButton.styleFrom(backgroundColor: Colors.black45)
              : null,
          icon: _ocupado
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Paleta.amarillo,
                  ),
                )
              : Icon(
                  guardado ? Icons.bookmark : Icons.bookmark_border,
                  color: guardado ? Paleta.amarillo : Paleta.papel,
                ),
        );
      },
    );
  }
}
