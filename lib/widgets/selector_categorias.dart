import 'package:flutter/material.dart';

import '../core/categorias_visual.dart';
import '../core/tema.dart';
import '../modelos/evento.dart';
import '../servicios/catalogo_servicio.dart';

/// Cuadrícula de categorías que se pueden marcar y desmarcar (RF-PU-03).
/// La usan el onboarding y la pantalla "Mis intereses".
class SelectorCategorias extends StatefulWidget {
  const SelectorCategorias({
    super.key,
    required this.seleccionadas,
    required this.alCambiar,
  });

  final Set<int> seleccionadas;
  final ValueChanged<Set<int>> alCambiar;

  @override
  State<SelectorCategorias> createState() => _SelectorCategoriasState();
}

class _SelectorCategoriasState extends State<SelectorCategorias> {
  late Future<List<Categoria>> _futuro = CatalogoServicio().categorias();

  void _reintentar() {
    setState(() {
      _futuro = CatalogoServicio().categorias();
    });
  }

  void _alternar(int id) {
    final nuevas = {...widget.seleccionadas};
    if (!nuevas.remove(id)) nuevas.add(id);
    widget.alCambiar(nuevas);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Categoria>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.hasError) {
          return Column(
            children: [
              Text(
                'No pudimos cargar las categorías.',
                style: Tipografia.ui(14, color: Paleta.papelMut),
              ),
              TextButton(onPressed: _reintentar, child: const Text('Reintentar')),
            ],
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in snap.data!)
              _ChipInteres(
                categoria: c,
                activo: widget.seleccionadas.contains(c.id),
                alPresionar: () => _alternar(c.id),
              ),
          ],
        );
      },
    );
  }
}

class _ChipInteres extends StatelessWidget {
  const _ChipInteres({
    required this.categoria,
    required this.activo,
    required this.alPresionar,
  });

  final Categoria categoria;
  final bool activo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final colorTexto = activo ? Paleta.noche : Paleta.papel;
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
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activo ? Icons.check : iconoCategoria(categoria.slug),
                    size: 18,
                    color: colorTexto,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoria.nombre,
                    style: Tipografia.ui(
                      14,
                      peso: FontWeight.w700,
                      color: colorTexto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
