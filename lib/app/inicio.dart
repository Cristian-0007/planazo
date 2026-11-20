import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../pantallas/explorar_pantalla.dart';
import '../pantallas/favoritos_pantalla.dart';
import '../pantallas/perfil_pantalla.dart';
import '../pantallas/proximos_pantalla.dart';
import '../servicios/avisos_estado.dart';
import '../servicios/favoritos_estado.dart';

/// Contenedor principal con la barra de 4 destinos del kit.
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    // Los favoritos son de la sesión actual: se limpian y se leen de nuevo.
    FavoritosEstado.instancia.reiniciar();
    FavoritosEstado.instancia.cargar();
    // Avisos: se olvidan los de la sesión anterior y se crean los de "inicio
    // próximo" que falten.
    AvisosEstado.instancia.reiniciar();
    AvisosEstado.instancia.sincronizar();
  }

  static const _pantallas = <Widget>[
    ExplorarPantalla(),
    FavoritosPantalla(),
    ProximosPantalla(),
    PerfilPantalla(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack conserva el estado de cada pestaña al cambiar.
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Paleta.borde)),
        ),
        child: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) {
            setState(() {
              _indice = i;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Próximos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
