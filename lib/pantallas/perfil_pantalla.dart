import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/tema.dart';
import '../modelos/perfil.dart';
import '../servicios/perfil_servicio.dart';
import '../widgets/fila_ajuste.dart';
import 'editar_perfil_pantalla.dart';
import 'intereses_pantalla.dart';
import 'privacidad_pantalla.dart';
import 'seguridad_pantalla.dart';

/// Perfil: resumen de la cuenta y acceso a editar datos, intereses,
/// privacidad, seguridad y cierre de sesión.
class PerfilPantalla extends StatefulWidget {
  const PerfilPantalla({super.key});

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  final _servicio = PerfilServicio();
  late Future<Perfil?> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _servicio.cargar();
  }

  /// Abre una pantalla del perfil y, al volver, lee los datos otra vez.
  Future<void> _abrir(Widget pantalla) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
    if (!mounted) return;
    setState(() {
      _perfil = _servicio.cargar();
    });
  }

  Future<void> _cerrarSesion() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cerrar la sesión. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final correo = Supabase.instance.client.auth.currentUser?.email ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text('Perfil', style: Tipografia.display(31, espaciado: -0.6, altura: 1.05)),
          const SizedBox(height: 24),
          FutureBuilder<Perfil?>(
            future: _perfil,
            builder: (context, snap) {
              final nombre = snap.data?.nombre ?? '';
              final ciudad = snap.data?.ciudadNombre;
              final base = nombre.isNotEmpty ? nombre : correo;
              final inicial = base.isEmpty
                  ? '?'
                  : String.fromCharCode(base.runes.first).toUpperCase();

              return Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Paleta.noche3,
                      shape: BoxShape.circle,
                      border: Border.all(color: Paleta.borde),
                    ),
                    child: Text(inicial, style: Tipografia.display(26)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre.isEmpty ? 'Tu cuenta' : nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tipografia.display(25, peso: FontWeight.w600, espaciado: -0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          correo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tipografia.ui(14, color: Paleta.papelMut),
                        ),
                        if (ciudad != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Paleta.amarillo,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ciudad,
                                style: Tipografia.ui(
                                  13,
                                  peso: FontWeight.w600,
                                  color: Paleta.papelMut,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          FilaAjuste(
            icono: Icons.person_outline,
            titulo: 'Datos personales',
            subtitulo: 'Nombre, teléfono y ciudad',
            alPresionar: () => _abrir(const EditarPerfilPantalla()),
          ),
          const SizedBox(height: 10),
          FilaAjuste(
            icono: Icons.local_activity_outlined,
            titulo: 'Mis intereses',
            subtitulo: 'Categorías para personalizar Explorar',
            alPresionar: () => _abrir(const InteresesPantalla()),
          ),
          const SizedBox(height: 10),
          FilaAjuste(
            icono: Icons.shield_outlined,
            titulo: 'Privacidad y avisos',
            subtitulo: 'Tus datos, avisos y personalización',
            alPresionar: () => _abrir(const PrivacidadPantalla()),
          ),
          const SizedBox(height: 10),
          FilaAjuste(
            icono: Icons.lock_outline,
            titulo: 'Cuenta y seguridad',
            subtitulo: 'Cambiar correo y contraseña',
            alPresionar: () => _abrir(const SeguridadPantalla()),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
