import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/filtros.dart';
import '../core/tema.dart';
import '../modelos/ciudad.dart';
import '../servicios/avisos_estado.dart';
import '../servicios/eventos_servicio.dart';
import '../servicios/perfil_servicio.dart';
import '../servicios/preferencias_servicio.dart';
import '../widgets/aviso_sin_conexion.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_evento.dart';
import '../widgets/hoja_filtros.dart';
import 'avisos_pantalla.dart';
import 'ciudad_pantalla.dart';
import 'detalle_pantalla.dart';

/// Catálogo de eventos de la ciudad, con búsqueda por texto y filtros
/// combinables (RF-EU-01, RF-EU-02 y RF-EU-03). Lee los datos desde Supabase
/// y los ordena según las categorías de interés del perfil.
class ExplorarPantalla extends StatefulWidget {
  const ExplorarPantalla({super.key});

  @override
  State<ExplorarPantalla> createState() => _ExplorarPantallaState();
}

/// Catálogo y preferencias del perfil, cargados juntos.
class _Datos {
  const _Datos(this.catalogo, this.preferencias);

  final CatalogoEventos catalogo;
  final Preferencias preferencias;
}

class _ExplorarPantallaState extends State<ExplorarPantalla> {
  final _servicio = EventosServicio();
  final _preferenciasServicio = PreferenciasServicio();
  final _perfilServicio = PerfilServicio();
  final _busqueda = TextEditingController();
  late Future<_Datos> _futuro;
  FiltrosEventos _filtros = const FiltrosEventos();

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
    PreferenciasServicio.cambios.addListener(_alCambiarPreferencias);
  }

  @override
  void dispose() {
    PreferenciasServicio.cambios.removeListener(_alCambiarPreferencias);
    _busqueda.dispose();
    super.dispose();
  }

  /// El usuario cambió intereses, ciudad o consentimientos en su perfil:
  /// se vuelve a leer todo sin mostrar el indicador de carga.
  void _alCambiarPreferencias() {
    if (!mounted) return;
    setState(() {
      _futuro = _cargar();
    });
  }

  /// Toca la ciudad del encabezado: se elige otra y se guarda en el perfil.
  Future<void> _elegirCiudad(String? actualId) async {
    final ciudad = await Navigator.of(context).push<Ciudad>(
      MaterialPageRoute<Ciudad>(
        builder: (_) => CiudadPantalla(seleccionadaId: actualId),
      ),
    );
    if (ciudad == null || !mounted) return;
    try {
      await _perfilServicio.guardarCiudad(ciudad.id);
    } catch (e) {
      debugPrint('Error guardando la ciudad: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tu ciudad. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  void _abrirAvisos() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AvisosPantalla()),
    );
  }

  Future<_Datos> _cargar() async {
    // Las dos consultas arrancan a la vez y se esperan juntas.
    final catalogo = _servicio.cargar();
    final preferencias = _preferenciasServicio.cargar();
    return _Datos(await catalogo, await preferencias);
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {
      // El error se muestra en pantalla desde el FutureBuilder.
    }
  }

  void _cambiarFiltros(FiltrosEventos nuevos) {
    setState(() {
      _filtros = nuevos;
    });
  }

  void _limpiarTodo() {
    _busqueda.clear();
    _cambiarFiltros(const FiltrosEventos());
  }

  Future<void> _abrirFiltros(List<String> localidades) async {
    final r = await mostrarHojaFiltros(
      context,
      actuales: _filtros,
      localidades: localidades,
    );
    if (r != null) _cambiarFiltros(r);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_Datos>(
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

  Widget _contenido(_Datos datos) {
    final catalogo = datos.catalogo;
    final prefs = datos.preferencias;
    final ahora = DateTime.now();

    // Si el usuario eligió una ciudad, solo se ven los eventos de esa ciudad.
    final base = catalogo.eventos.where((e) {
      if (e.estado == 'finalizado') return false;
      final ciudad = prefs.ciudadId;
      return ciudad == null || e.lugar?.ciudadId == ciudad;
    }).toList();

    final lista = aplicarFiltros(
      base,
      _filtros,
      ahora: ahora,
      categoriasPreferidas: prefs.categoriaIds,
    );
    final localidades = localidadesDe(base);

    return RefreshIndicator(
      color: Paleta.amarillo,
      backgroundColor: Paleta.noche2,
      onRefresh: _refrescar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _Encabezado(
              ciudad: prefs.ciudadNombre,
              alPresionar: () => _elegirCiudad(prefs.ciudadId),
              alAvisos: _abrirAvisos,
            ),
          ),
          // Franja que aparece solo cuando se muestran datos guardados.
          const SliverToBoxAdapter(child: AvisoSinConexion()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busqueda,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => _cambiarFiltros(_filtros.copiar(texto: v)),
                      decoration: decoracionCampo(
                        etiqueta: 'Buscar planes',
                        icono: Icons.search,
                        sufijo: _filtros.texto.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Borrar búsqueda',
                                icon: const Icon(Icons.close, color: Paleta.papelMut),
                                onPressed: () {
                                  _busqueda.clear();
                                  _cambiarFiltros(_filtros.copiar(texto: ''));
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _BotonFiltros(
                    activos: _filtros.avanzadosActivos,
                    alPresionar: () => _abrirFiltros(localidades),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: [
                  ChipFiltro(
                    etiqueta: 'Todos',
                    activo: _filtros.categoriaSlug == null,
                    alPresionar: () =>
                        _cambiarFiltros(_filtros.copiar(quitarCategoria: true)),
                  ),
                  for (final c in catalogo.categorias) ...[
                    const SizedBox(width: 8),
                    ChipFiltro(
                      etiqueta: c.nombre,
                      activo: _filtros.categoriaSlug == c.slug,
                      alPresionar: () =>
                          _cambiarFiltros(_filtros.copiar(categoriaSlug: c.slug)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Resumen(
              total: lista.length,
              hayFiltros: _filtros.hayAlgunoActivo,
              personalizado: prefs.tieneCategorias,
              alLimpiar: _limpiarTodo,
            ),
          ),
          if (lista.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _filtros.hayAlgunoActivo
                  ? EstadoVacio(
                      icono: Icons.search_off,
                      titulo: 'Sin resultados',
                      mensaje:
                          'No encontramos planes con esa búsqueda. Prueba con otras palabras o quita algún filtro.',
                      textoBoton: 'Quitar filtros',
                      alPresionar: _limpiarTodo,
                    )
                  : const EstadoVacio(
                      icono: Icons.event_busy,
                      titulo: 'Sin planes por ahora',
                      mensaje: 'Vuelve más tarde: estamos actualizando el catálogo.',
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
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
  const _Encabezado({
    required this.ciudad,
    required this.alPresionar,
    required this.alAvisos,
  });

  /// null = el usuario aún no eligió una ciudad.
  final String? ciudad;
  final VoidCallback alPresionar;
  final VoidCallback alAvisos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: ciudad == null
                        ? 'Elegir ciudad'
                        : 'Ciudad: $ciudad. Cambiar',
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radios.sm),
                      onTap: alPresionar,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Paleta.amarillo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ciudad ?? 'Elige tu ciudad',
                              style: Tipografia.ui(
                                13,
                                peso: FontWeight.w600,
                                color: Paleta.papelMut,
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Paleta.papelMut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _CampanaAvisos(alPresionar: alAvisos),
            ],
          ),
          Text(
            'Descubre planes',
            style: Tipografia.display(31, espaciado: -0.6, altura: 1.05),
          ),
        ],
      ),
    );
  }
}

/// Botón de la derecha del buscador; muestra cuántos filtros hay activos.
class _BotonFiltros extends StatelessWidget {
  const _BotonFiltros({required this.activos, required this.alPresionar});

  final int activos;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final hay = activos > 0;
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        tooltip: hay ? 'Filtros ($activos activos)' : 'Filtros',
        onPressed: alPresionar,
        style: IconButton.styleFrom(
          backgroundColor: hay ? Paleta.amarillo : Paleta.noche2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radios.sm),
            side: BorderSide(color: hay ? Paleta.amarillo : Paleta.borde),
          ),
        ),
        icon: Badge(
          isLabelVisible: hay,
          label: Text('$activos'),
          child: Icon(Icons.tune, color: hay ? Paleta.noche : Paleta.papel),
        ),
      ),
    );
  }
}

/// Línea bajo los chips: cuántos resultados hay, o por qué van en ese orden.
class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.total,
    required this.hayFiltros,
    required this.personalizado,
    required this.alLimpiar,
  });

  final int total;
  final bool hayFiltros;
  final bool personalizado;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    if (!hayFiltros && !personalizado) return const SizedBox(height: 4);

    final texto = hayFiltros
        ? (total == 1 ? '1 plan encontrado' : '$total planes encontrados')
        : 'Ordenado según tus categorías de interés';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                texto,
                style: Tipografia.ui(13, peso: FontWeight.w600, color: Paleta.papelMut),
              ),
            ),
          ),
          if (hayFiltros)
            TextButton(onPressed: alLimpiar, child: const Text('Limpiar')),
        ],
      ),
    );
  }
}

/// Campana del encabezado: abre la bandeja y muestra cuántos avisos
/// están sin leer.
class _CampanaAvisos extends StatelessWidget {
  const _CampanaAvisos({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AvisosEstado.instancia,
      builder: (context, _) {
        final n = AvisosEstado.instancia.noLeidos;
        return IconButton(
          tooltip: n > 0 ? 'Avisos ($n sin leer)' : 'Avisos',
          onPressed: alPresionar,
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n > 9 ? '9+' : '$n'),
            child: const Icon(Icons.notifications_none, color: Paleta.papel),
          ),
        );
      },
    );
  }
}