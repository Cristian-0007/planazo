import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../modelos/evento.dart';
import '../servicios/eventos_servicio.dart';
import '../servicios/favoritos_estado.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_evento.dart';
import 'detalle_pantalla.dart';

/// Agenda con los favoritos que están por ocurrir en un rango cercano de
/// tiempo (RF-EU-06). Funciona como recordatorio de los planes ya elegidos.
class ProximosPantalla extends StatefulWidget {
  const ProximosPantalla({super.key});

  /// Cuántos días hacia adelante cuenta como "cercano".
  static const diasAdelante = 30;

  @override
  State<ProximosPantalla> createState() => _ProximosPantallaState();
}

class _ProximosPantallaState extends State<ProximosPantalla> {
  final _servicio = EventosServicio();
  late Future<CatalogoEventos> _futuro;

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
                debugPrint('Error cargando próximos: ${snap.error}');
                return EstadoVacio(
                  icono: Icons.wifi_off,
                  titulo: 'No pudimos cargar tu agenda',
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
    final ahora = DateTime.now();
    final limite = ahora.add(const Duration(days: ProximosPantalla.diasAdelante));

    // Solo favoritos que todavía pueden ocurrir y empiezan dentro del rango.
    final lista = catalogo.eventos.where((e) {
      if (!ids.contains(e.id)) return false;
      if (e.estado == 'cancelado' || e.estado == 'finalizado') return false;
      return e.iniciaEn.isBefore(limite);
    }).toList()
      ..sort((a, b) => a.iniciaEn.compareTo(b.iniciaEn));

    final grupos = _agrupar(lista, ahora);

    return RefreshIndicator(
      color: Paleta.amarillo,
      backgroundColor: Paleta.noche2,
      onRefresh: _refrescar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _Encabezado()),
          if (lista.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoVacio(
                icono: Icons.calendar_today_outlined,
                titulo: ids.isEmpty ? 'Tu agenda está vacía' : 'Sin planes cercanos',
                mensaje: ids.isEmpty
                    ? 'Guarda eventos como favoritos y aquí verás los que están por llegar.'
                    : 'Ninguno de tus favoritos empieza en los próximos '
                        '${ProximosPantalla.diasAdelante} días.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final g in grupos) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 2),
                      child: Text(
                        g.titulo,
                        style: Tipografia.display(
                          18,
                          espaciado: -0.2,
                          color: Paleta.amarillo,
                        ),
                      ),
                    ),
                    for (var i = 0; i < g.eventos.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: Paleta.borde),
                      FilaEvento(
                        evento: g.eventos[i],
                        alPresionar: () => abrirDetalle(context, g.eventos[i]),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }

  /// Los eventos en curso van primero bajo "Ahora"; el resto, por día.
  List<_Grupo> _agrupar(List<Evento> lista, DateTime ahora) {
    final grupos = <_Grupo>[];

    final enCurso = lista.where((e) => e.estado == 'en_curso').toList();
    if (enCurso.isNotEmpty) grupos.add(_Grupo('Ahora', enCurso));

    for (final e in lista.where((e) => e.estado != 'en_curso')) {
      final titulo = etiquetaDia(e.iniciaEn, ahora);
      final ultimo = grupos.isEmpty ? null : grupos.last;
      if (ultimo != null &&
          ultimo.titulo != 'Ahora' &&
          diasEntre(ultimo.eventos.first.iniciaEn, e.iniciaEn) == 0) {
        ultimo.eventos.add(e);
      } else {
        grupos.add(_Grupo(titulo, [e]));
      }
    }
    return grupos;
  }
}

class _Grupo {
  _Grupo(this.titulo, this.eventos);

  final String titulo;
  final List<Evento> eventos;
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos planes',
            style: Tipografia.display(31, espaciado: -0.6, altura: 1.05),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus favoritos de los próximos ${ProximosPantalla.diasAdelante} días',
            style: Tipografia.ui(14, color: Paleta.papelMut),
          ),
        ],
      ),
    );
  }
}
