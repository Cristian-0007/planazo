import 'package:flutter/material.dart';

import '../core/categorias_visual.dart';
import '../core/formato.dart';
import '../core/tema.dart';
import '../modelos/evento.dart';
import 'estado_chip.dart';
import 'sello_fecha.dart';

/// Fila de evento para listas (Explorar, Favoritos, Próximos).
class FilaEvento extends StatelessWidget {
  const FilaEvento({super.key, required this.evento, this.alPresionar});

  final Evento evento;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final apagado =
        evento.estado == 'cancelado' || evento.estado == 'finalizado';

    final lugar = evento.lugar;
    final meta = lugar == null
        ? null
        : [lugar.nombre, if (lugar.localidad != null) lugar.localidad!]
            .join(' · ');

    return Opacity(
      opacity: apagado ? 0.65 : 1,
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(Radios.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _Miniatura(evento: evento),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Tipografia.ui(15, peso: FontWeight.w700, altura: 1.25),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
                      ),
                    ],
                    Text(
                      fechaYHora(evento.iniciaEn),
                      style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          textoPrecio(evento.precio),
                          style: Tipografia.ui(
                            13,
                            peso: FontWeight.w800,
                            color: Paleta.amarillo,
                          ),
                        ),
                        EstadoChip(estado: evento.estado),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final degradado = DecoratedBox(
      decoration: BoxDecoration(
        gradient: degradadoCategoria(evento.categoria?.slug),
      ),
    );

    return SizedBox(
      width: 76,
      height: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radios.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (evento.imagenUrl != null)
              Image.network(
                evento.imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => degradado,
              )
            else
              degradado,
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SelloFecha(fecha: evento.iniciaEn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
