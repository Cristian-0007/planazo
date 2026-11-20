import 'package:flutter/material.dart';
import '../core/categorias_visual.dart';
import '../core/formato.dart';
import '../core/mapa.dart';
import '../core/tema.dart';
import '../modelos/evento.dart';
import '../widgets/boton_favorito.dart';
import '../widgets/estado_chip.dart';

/// Abre el detalle de un evento (RF-GE-01).
void abrirDetalle(BuildContext context, Evento evento) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DetallePantalla(evento: evento)),
  );
}

/// Información completa del evento, con su estado y el botón de favorito.
class DetallePantalla extends StatelessWidget {
  const DetallePantalla({super.key, required this.evento});

  final Evento evento;

  /// Hora de fin: solo la hora si termina el mismo día, fecha y hora si no.
  String? _textoFin() {
    final fin = evento.terminaEn;
    if (fin == null) return null;
    final ini = evento.iniciaEn;
    final mismoDia =
        fin.year == ini.year && fin.month == ini.month && fin.day == ini.day;
    return mismoDia ? 'Hasta ${hora12(fin)}' : 'Hasta ${fechaYHora(fin)}';
  }

  String _textoEdad() {
    final edad = evento.edadMinima;
    if (edad == null || edad == 0) return 'Para todo público';
    return 'Mayores de $edad años';
  }

  /// Abre Google Maps en el lugar del evento (RF-GE-02).
  Future<void> _comoLlegar(BuildContext context, Lugar lugar) async {
    var abierto = false;
    try {
      abierto = await abrirMapa(
        latitud: lugar.latitud,
        longitud: lugar.longitud,
        nombre: lugar.nombre,
        direccion: lugar.direccion,
      );
    } catch (_) {
      abierto = false;
    }
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lugar = evento.lugar;
    final fin = _textoFin();
    final descripcion = evento.descripcion?.trim() ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Paleta.noche,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton.filled(
                tooltip: 'Volver',
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Paleta.papel),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: BotonFavorito(eventoId: evento.id, sobreImagen: true),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Portada(evento: evento),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      EstadoChip(estado: evento.estado),
                      if (evento.categoria != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconoCategoria(evento.categoria!.slug),
                              size: 16,
                              color: Paleta.papelMut,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              evento.categoria!.nombre,
                              style: Tipografia.ui(
                                13,
                                peso: FontWeight.w600,
                                color: Paleta.papelMut,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    evento.nombre,
                    style: Tipografia.display(31, espaciado: -0.6, altura: 1.08),
                  ),
                  _Aviso(estado: evento.estado),
                  const SizedBox(height: 22),
                  _Dato(
                    icono: Icons.calendar_today_outlined,
                    titulo: 'Fecha y hora',
                    lineas: [fechaYHora(evento.iniciaEn), ?fin],
                  ),
                  if (lugar != null) ...[
                    _Dato(
                      icono: Icons.location_on_outlined,
                      titulo: 'Lugar',
                      lineas: [
                        lugar.nombre,
                        if (lugar.direccion != null) lugar.direccion!,
                        if (lugar.localidad != null)
                          'Localidad ${lugar.localidad}',
                      ],
                    ),
                    // Botón alineado con el texto de arriba (40 icono + 14 espacio).
                    Padding(
                      padding: const EdgeInsets.only(left: 54, bottom: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _comoLlegar(context, lugar),
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: const Text('Cómo llegar'),
                        ),
                      ),
                    ),
                  ],
                  _Dato(
                    icono: Icons.sell_outlined,
                    titulo: 'Precio',
                    lineas: [textoPrecio(evento.precio)],
                    destacado: true,
                  ),
                  _Dato(
                    icono: Icons.group_outlined,
                    titulo: 'Edad',
                    lineas: [_textoEdad()],
                  ),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Acerca del plan',
                      style: Tipografia.display(20, espaciado: -0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final degradado = DecoratedBox(
      decoration: BoxDecoration(
        gradient: degradadoCategoria(evento.categoria?.slug),
      ),
      child: Center(
        child: Icon(
          iconoCategoria(evento.categoria?.slug),
          size: 72,
          color: Colors.white54,
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (evento.imagenUrl != null)
          Image.network(
            evento.imagenUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => degradado,
          )
        else
          degradado,
        // Sombra arriba para que los botones se lean sobre cualquier foto.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.black38, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mensaje claro cuando el plan ya no está disponible (información veraz).
class _Aviso extends StatelessWidget {
  const _Aviso({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (String? texto, Color color) = switch (estado) {
      'cancelado' => ('El organizador canceló este evento.', Paleta.fucsia),
      'sin_cupos' => ('Se agotaron los cupos de este evento.', Paleta.naranja),
      'finalizado' => ('Este evento ya terminó.', Paleta.papelMut),
      _ => (null, Paleta.papelMut),
    };
    if (texto == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          texto,
          style: Tipografia.ui(14, peso: FontWeight.w700, color: color, altura: 1.4),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.titulo,
    required this.lineas,
    this.destacado = false,
  });

  final IconData icono;
  final String titulo;
  final List<String> lineas;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Paleta.noche2,
              borderRadius: BorderRadius.circular(Radios.sm),
              border: Border.all(color: Paleta.borde),
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
                  style: Tipografia.ui(12, peso: FontWeight.w700, color: Paleta.papelMut),
                ),
                const SizedBox(height: 2),
                for (var i = 0; i < lineas.length; i++)
                  Text(
                    lineas[i],
                    style: i == 0
                        ? Tipografia.ui(
                            15,
                            peso: FontWeight.w700,
                            altura: 1.35,
                            color: destacado ? Paleta.amarillo : Paleta.papel,
                          )
                        : Tipografia.ui(14, color: Paleta.papelMut, altura: 1.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
