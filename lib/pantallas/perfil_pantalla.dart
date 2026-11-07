import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/tema.dart';

/// Perfil básico: lee el perfil que el trigger de la base de datos crea al
/// registrarse, y permite cerrar sesión.
class PerfilPantalla extends StatefulWidget {
  const PerfilPantalla({super.key});

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  late final Future<Map<String, dynamic>?> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _cargarPerfil();
  }

  Future<Map<String, dynamic>?> _cargarPerfil() async {
    final db = Supabase.instance.client;
    final id = db.auth.currentUser?.id;
    if (id == null) return null;
    return await db
        .from('perfiles')
        .select('nombre, acepta_terminos')
        .eq('id', id)
        .maybeSingle();
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
          FutureBuilder<Map<String, dynamic>?>(
            future: _perfil,
            builder: (context, snap) {
              final nombre = (snap.data?['nombre'] as String?) ?? '';
              final base = nombre.isNotEmpty ? nombre : correo;
              final inicial = base.isEmpty
                  ? '?'
                  : String.fromCharCode(base.runes.first).toUpperCase();
              final acepto = snap.data?['acepta_terminos'] == true;

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
                        if (acepto) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tratamiento de datos: aceptado',
                            style: Tipografia.ui(13, peso: FontWeight.w600, color: Paleta.menta),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
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
