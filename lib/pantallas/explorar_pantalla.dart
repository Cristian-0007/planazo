import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../servicios/eventos_servicio.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_evento.dart';

/// Lista de eventos de Bogotá, con filtro por categoría.
/// Lee los datos reales desde Supabase.
class ExplorarPantalla extends StatefulWidget {
  const ExplorarPantalla({super.key});

  @override
  State<ExplorarPantalla> createState() => _ExplorarPantallaState();
}

class _ExplorarPantallaState extends State<ExplorarPantalla> {
  final _servicio = EventosServicio();
  late Future<CatalogoEventos> _futuro;
  String? _slug; // null = todas las categorías

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.cargar();
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.cargar();
    });
  }

  Future<void> _refrescar() async {
    final f = _servicio.cargar();
    setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {
      // El error se muestra en pantalla desde el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<CatalogoEventos>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.hasData) return _contenido(snap.data!);

          if (snap.hasError) {
            debugPrint('Error cargando eventos: ${snap.error}');
            return EstadoVacio(
              icono: Icons.wifi_off,
              titulo: 'No pudimos cargar los eventos',
              mensaje: kDebugMode
                  ? '${snap.error}'
                  : 'Revisa tu conexión e inténtalo de nuevo.',
              textoBoton: 'Reintentar',
              alPresionar: _recargar,
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _contenido(CatalogoEventos catalogo) {
    final lista = catalogo.eventos.where((e) {
      if (e.estado == 'finalizado') return false;
      return _slug == null || e.categoria?.slug == _slug;
    }).toList();

    return RefreshIndicator(
      color: Paleta.amarillo,
      backgroundColor: Paleta.noche2,
      onRefresh: _refrescar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Encabezado()),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: [
                  _ChipFiltro(
                    etiqueta: 'Todos',
                    activo: _slug == null,
                    alPresionar: () {
                      setState(() {
                        _slug = null;
                      });
                    },
                  ),
                  for (final c in catalogo.categorias) ...[
                    const SizedBox(width: 8),
                    _ChipFiltro(
                      etiqueta: c.nombre,
                      activo: _slug == c.slug,
                      alPresionar: () {
                        setState(() {
                          _slug = c.slug;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (lista.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoVacio(
                icono: Icons.event_busy,
                titulo: 'Sin planes por ahora',
                mensaje:
                    'No hay eventos en esta categoría. Prueba con otra o vuelve más tarde.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              sliver: SliverList.separated(
                itemCount: lista.length,
                itemBuilder: (context, i) => FilaEvento(evento: lista[i]),
                separatorBuilder: (context, i) =>
                    const Divider(height: 1, color: Paleta.borde),
              ),
            ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Paleta.amarillo),
              const SizedBox(width: 4),
              Text(
                'Bogotá',
                style: Tipografia.ui(13, peso: FontWeight.w600, color: Paleta.papelMut),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Descubre planes',
            style: Tipografia.display(31, espaciado: -0.6, altura: 1.05),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
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
