import 'package:flutter/material.dart';

import '../core/categorias_visual.dart';
import '../core/tema.dart';
import '../modelos/ciudad.dart';
import '../servicios/perfil_servicio.dart';
import '../widgets/selector_categorias.dart';
import '../widgets/selector_ciudad.dart';

/// Bienvenida del primer arranque (RF-GIA-05): tres pantallas que explican
/// la app y dos pasos para elegir intereses y ciudad. Todo se puede omitir.
class OnboardingPantalla extends StatefulWidget {
  const OnboardingPantalla({super.key, required this.alTerminar});

  /// Se llama cuando el onboarding quedó marcado como completo.
  final VoidCallback alTerminar;

  @override
  State<OnboardingPantalla> createState() => _OnboardingPantallaState();
}

class _OnboardingPantallaState extends State<OnboardingPantalla> {
  static const _totalPaginas = 5;

  final _servicio = PerfilServicio();
  final _controlador = PageController();
  int _pagina = 0;
  bool _guardando = false;
  Set<int> _categorias = {};
  Ciudad? _ciudad;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _moverA(int pagina) {
    _controlador.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _siguiente() {
    if (_pagina < _totalPaginas - 1) {
      _moverA(_pagina + 1);
    } else {
      _terminar(guardar: true);
    }
  }

  Future<void> _terminar({required bool guardar}) async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
    });
    try {
      await _servicio.completarOnboarding(
        categorias: guardar ? _categorias : const {},
        ciudadId: guardar ? _ciudad?.id : null,
      );
      if (!mounted) return;
      widget.alTerminar();
    } catch (e) {
      debugPrint('Error terminando el onboarding: $e');
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos guardar tus preferencias. Revisa tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _pagina == _totalPaginas - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: TextButton(
                  onPressed: _guardando ? null : () => _terminar(guardar: false),
                  child: const Text('Omitir'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controlador,
                onPageChanged: (i) {
                  setState(() {
                    _pagina = i;
                  });
                },
                children: [
                  const _PaginaInfo(
                    slug: 'musica',
                    icono: Icons.explore_outlined,
                    titulo: 'Descubre',
                    texto:
                        'Música, cine, gastronomía, deportes, arte y más: los planes de tu ciudad en un solo lugar.',
                  ),
                  const _PaginaInfo(
                    slug: 'cine',
                    icono: Icons.tune,
                    titulo: 'Elige',
                    texto:
                        'Busca y filtra por categoría, fecha, precio y zona para encontrar el plan que va contigo.',
                  ),
                  const _PaginaInfo(
                    slug: 'gastronomia',
                    icono: Icons.bookmark_border,
                    titulo: 'Guarda',
                    texto:
                        'Marca tus favoritos, revisa en Próximos lo que viene y te avisamos si algo se cancela.',
                  ),
                  _PaginaPaso(
                    titulo: '¿Qué te gusta?',
                    texto:
                        'Elige tus categorías para ver primero lo que más te interesa. Puedes cambiarlas después en tu perfil.',
                    child: SelectorCategorias(
                      seleccionadas: _categorias,
                      alCambiar: (nuevas) {
                        setState(() {
                          _categorias = nuevas;
                        });
                      },
                    ),
                  ),
                  _PaginaPaso(
                    titulo: '¿Dónde buscas planes?',
                    texto:
                        'Elige tu ciudad o usa tu ubicación. La usamos una sola vez y no la guardamos.',
                    child: SelectorCiudad(
                      seleccionadaId: _ciudad?.id,
                      alElegir: (c) {
                        setState(() {
                          _ciudad = c;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  _Puntos(total: _totalPaginas, actual: _pagina),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (_pagina > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _guardando ? null : () => _moverA(_pagina - 1),
                            child: const Text('Atrás'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _guardando ? null : _siguiente,
                          child: _guardando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Paleta.noche,
                                  ),
                                )
                              : Text(ultima ? 'Empezar' : 'Siguiente'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginaInfo extends StatelessWidget {
  const _PaginaInfo({
    required this.slug,
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final String slug;
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                gradient: degradadoCategoria(slug),
                borderRadius: BorderRadius.circular(Radios.xl),
              ),
              child: Icon(icono, size: 60, color: Paleta.papel),
            ),
            const SizedBox(height: 32),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Tipografia.display(40, espaciado: -1, altura: 1),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: Tipografia.ui(16, color: Paleta.papelMut, altura: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginaPaso extends StatelessWidget {
  const _PaginaPaso({
    required this.titulo,
    required this.texto,
    required this.child,
  });

  final String titulo;
  final String texto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Tipografia.display(31, espaciado: -0.6, altura: 1.05)),
          const SizedBox(height: 10),
          Text(
            texto,
            style: Tipografia.ui(15, color: Paleta.papelMut, altura: 1.4),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _Puntos extends StatelessWidget {
  const _Puntos({required this.total, required this.actual});

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${actual + 1} de $total',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == actual ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == actual ? Paleta.amarillo : Paleta.borde,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }
}
