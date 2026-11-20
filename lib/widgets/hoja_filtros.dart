import 'package:flutter/material.dart';

import '../core/filtros.dart';
import '../core/tema.dart';
import 'chip_filtro.dart';

/// Abre la hoja con los filtros de fecha, precio y ubicación (RF-EU-03).
/// Devuelve los filtros nuevos, o null si el usuario la cierra sin aplicar.
Future<FiltrosEventos?> mostrarHojaFiltros(
  BuildContext context, {
  required FiltrosEventos actuales,
  required List<String> localidades,
}) {
  return showModalBottomSheet<FiltrosEventos>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Paleta.noche,
    elevation: 0,
    builder: (_) => _HojaFiltros(actuales: actuales, localidades: localidades),
  );
}

class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({required this.actuales, required this.localidades});

  final FiltrosEventos actuales;
  final List<String> localidades;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late FiltroFecha _fecha = widget.actuales.fecha;
  late FiltroPrecio _precio = widget.actuales.precio;
  late String? _localidad = widget.actuales.localidad;

  void _limpiar() {
    setState(() {
      _fecha = FiltroFecha.cualquiera;
      _precio = FiltroPrecio.cualquiera;
      _localidad = null;
    });
  }

  void _aplicar() {
    Navigator.of(context).pop(
      widget.actuales.copiar(
        fecha: _fecha,
        precio: _precio,
        localidad: _localidad,
        quitarLocalidad: _localidad == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: Tipografia.display(26, espaciado: -0.5),
                  ),
                ),
                TextButton(onPressed: _limpiar, child: const Text('Limpiar')),
              ],
            ),
            const _Titulo('Fecha'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in FiltroFecha.values)
                  ChipFiltro(
                    etiqueta: f.etiqueta,
                    activo: _fecha == f,
                    alPresionar: () {
                      setState(() {
                        _fecha = f;
                      });
                    },
                  ),
              ],
            ),
            const _Titulo('Precio'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in FiltroPrecio.values)
                  ChipFiltro(
                    etiqueta: p.etiqueta,
                    activo: _precio == p,
                    alPresionar: () {
                      setState(() {
                        _precio = p;
                      });
                    },
                  ),
              ],
            ),
            if (widget.localidades.isNotEmpty) ...[
              const _Titulo('Ubicación (localidad)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChipFiltro(
                    etiqueta: 'Todas',
                    activo: _localidad == null,
                    alPresionar: () {
                      setState(() {
                        _localidad = null;
                      });
                    },
                  ),
                  for (final l in widget.localidades)
                    ChipFiltro(
                      etiqueta: l,
                      activo: _localidad == l,
                      alPresionar: () {
                        setState(() {
                          _localidad = l;
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _aplicar, child: const Text('Ver resultados')),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        texto,
        style: Tipografia.ui(13, peso: FontWeight.w700, color: Paleta.papelMut),
      ),
    );
  }
}
