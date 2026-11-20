import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../servicios/perfil_servicio.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/pantalla_interna.dart';
import '../widgets/selector_categorias.dart';

/// Elegir las categorías de interés para personalizar Explorar (RF-PU-03).
class InteresesPantalla extends StatefulWidget {
  const InteresesPantalla({super.key});

  @override
  State<InteresesPantalla> createState() => _InteresesPantallaState();
}

class _InteresesPantallaState extends State<InteresesPantalla> {
  final _servicio = PerfilServicio();
  Set<int> _elegidas = {};
  bool _cargando = true;
  bool _error = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final ids = await _servicio.categoriasDelPerfil();
      if (!mounted) return;
      setState(() {
        _elegidas = ids;
        _cargando = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Error cargando intereses: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = false;
    });
    _cargar();
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
    });
    try {
      await _servicio.guardarCategorias(_elegidas);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intereses guardados.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error guardando intereses: $e');
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tus intereses. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaInterna(titulo: 'Mis intereses', child: _cuerpo());
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return EstadoVacio(
        icono: Icons.wifi_off,
        titulo: 'No pudimos cargar tus intereses',
        mensaje: 'Revisa tu conexión e inténtalo de nuevo.',
        textoBoton: 'Reintentar',
        alPresionar: _reintentar,
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            children: [
              Text(
                'Marca lo que más te gusta y verás esos planes primero en Explorar.',
                style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
              ),
              const SizedBox(height: 18),
              SelectorCategorias(
                seleccionadas: _elegidas,
                alCambiar: (nuevas) {
                  setState(() {
                    _elegidas = nuevas;
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Paleta.noche,
                    ),
                  )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
