import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../servicios/eventos_servicio.dart';
import '../servicios/favoritos_estado.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_evento.dart';
import 'detalle_pantalla.dart';

/// Todos los eventos que el usuario guardó, pasados y futuros (RF-EU-05),
/// con opción de ordenarlos por fecha.
class FavoritosPantalla extends StatefulWidget {
  const FavoritosPantalla({super.key});

  @override
  State<FavoritosPantalla> createState() => _FavoritosPantallaState();
}

class _FavoritosPantallaState extends State<FavoritosPantalla> {
  final _servicio = EventosServicio();
  late Future<CatalogoEventos> _futuro;
  bool _cercanosPrimero = true;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.cargar();
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.cargar();
    });
    FavoritosEstado.instancia.cargar();
  }

  Future<void> _refrescar() async {
    final f = _servicio.cargar();
    setState(() {
      _futuro = f;
    });
    try {
      await Future.wait<void>([f, FavoritosEstado.instancia.cargar()]);
    } catch (_) {
      // El error se muestra en pantalla desde el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: FavoritosEstado.instancia,
        builder: (context, _) {
          final favoritos = FavoritosEstado.instancia;

          return FutureBuilder<CatalogoEventos>(
            future: _futuro,
            builder: (context, snap) {
              if (snap.hasError || (favoritos.hayError && !favoritos.cargado)) {
                debugPrint('Error cargando favoritos: ${snap.error}');
                return EstadoVacio(
                  icono: Icons.wifi_off,
                  titulo: 'No pudimos cargar tus favoritos',
                  mensaje: kDebugMode && snap.hasError
                      ? '${snap.error}'
                      : 'Revisa tu conexión e inténtalo de nuevo.',
                  textoBoton: 'Reintentar',
                  alPresionar: _recargar,
                );
              }
              if (!snap.hasData || !favoritos.cargado) {
                return const Center(child: CircularProgressIndicator());
              }
              return _contenido(snap.data!, favoritos.ids);
            },
          );
        },
      ),
    );
  }

  Widget _contenido(CatalogoEventos catalogo, Set<String> ids) {
    final lista = catalogo.eventos.where((e) => ids.contains(e.id)).toList()
      ..sort((a, b) => _cercanosPrimero
          ? a.iniciaEn.compareTo(b.iniciaEn)
          : b.iniciaEn.compareTo(a.iniciaEn));

    return RefreshIndicator(
      color: Paleta.amarillo,
      backgroundColor: Paleta.noche2,
      onRefresh: _refrescar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Encabezado(total: lista.length)),
          if (lista.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  children: [
                    ChipFiltro(
                      etiqueta: 'Más cercanos primero',
                      activo: _cercanosPrimero,
                      alPresionar: () {
                        setState(() {
                          _cercanosPrimero = true;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChipFiltro(
                      etiqueta: 'Más lejanos primero',
                      activo: !_cercanosPrimero,
                      alPresionar: () {
                        setState(() {
                          _cercanosPrimero = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (lista.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoVacio(
                icono: Icons.bookmark_border,
                titulo: 'Aún no guardas planes',
                mensaje:
                    'Toca el marcador de un evento para guardarlo y lo verás aquí.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              sliver: SliverList.separated(
                itemCount: lista.length,
                itemBuilder: (context, i) => FilaEvento(
                  evento: lista[i],
                  alPresionar: () => abrirDetalle(context, lista[i]),
                ),
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
  const _Encabezado({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus favoritos',
            style: Tipografia.display(31, espaciado: -0.6, altura: 1.05),
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              total == 1 ? '1 plan guardado' : '$total planes guardados',
              style: Tipografia.ui(14, color: Paleta.papelMut),
            ),
          ],
        ],
      ),
    );
  }
}
