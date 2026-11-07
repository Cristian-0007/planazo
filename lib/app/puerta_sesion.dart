import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pantallas/acceso_pantalla.dart';
import 'inicio.dart';

/// Decide qué mostrar según haya o no una sesión iniciada.
/// Supabase guarda la sesión en el dispositivo, así que al volver a abrir
/// la app el usuario sigue dentro.
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final sesion = snapshot.data?.session ?? auth.currentSession;
        if (sesion == null) return const AccesoPantalla();
        return const Inicio();
      },
    );
  }
}
