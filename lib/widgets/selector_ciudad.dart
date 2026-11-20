import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../modelos/ciudad.dart';
import '../servicios/catalogo_servicio.dart';
import '../servicios/ubicacion_servicio.dart';

/// Lista de ciudades más el botón "Usar mi ubicación" (RF-PU-04).
/// No guarda nada: avisa con [alElegir] y quien lo usa decide qué hacer.
class SelectorCiudad extends StatefulWidget {
  const SelectorCiudad({
    super.key,
    required this.alElegir,
    this.seleccionadaId,
  });

  final String? seleccionadaId;
  final ValueChanged<Ciudad> alElegir;

  @override
  State<SelectorCiudad> createState() => _SelectorCiudadState();
}

class _SelectorCiudadState extends State<SelectorCiudad> {
  late Future<List<Ciudad>> _futuro = CatalogoServicio().ciudades();
  bool _buscando = false;
  String? _mensaje;

  void _reintentar() {
    setState(() {
      _futuro = CatalogoServicio().ciudades();
    });
  }

  Future<void> _usarUbicacion(List<Ciudad> ciudades) async {
    setState(() {
      _buscando = true;
      _mensaje = null;
    });
    final r = await UbicacionServicio().ciudadCercana(ciudades);
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _mensaje = r.mensaje;
    });
    final ciudad = r.ciudad;
    if (ciudad != null) widget.alElegir(ciudad);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ciudad>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.hasError) {
          return Column(
            children: [
              Text(
                'No pudimos cargar las ciudades.',
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

        final ciudades = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _buscando ? null : () => _usarUbicacion(ciudades),
              icon: _buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 20),
              label: const Text('Usar mi ubicación'),
            ),
            if (_mensaje != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  _mensaje!,
                  style: Tipografia.ui(
                    13,
                    peso: FontWeight.w600,
                    color: Paleta.papelMut,
                    altura: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (final c in ciudades) ...[
              _FilaCiudad(
                ciudad: c,
                activa: c.id == widget.seleccionadaId,
                alPresionar: () => widget.alElegir(c),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _FilaCiudad extends StatelessWidget {
  const _FilaCiudad({
    required this.ciudad,
    required this.activa,
    required this.alPresionar,
  });

  final Ciudad ciudad;
  final bool activa;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activa,
      child: Material(
        color: Paleta.noche2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.md),
          side: BorderSide(
            color: activa ? Paleta.amarillo : Paleta.borde,
            width: activa ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radios.md),
          ),
          onTap: alPresionar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Paleta.papelMut),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      ciudad.nombre,
                      style: Tipografia.ui(16, peso: FontWeight.w700),
                    ),
                  ),
                  if (activa)
                    const Icon(Icons.check_circle, color: Paleta.amarillo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
