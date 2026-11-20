import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pantallas/acceso_pantalla.dart';
import '../pantallas/onboarding_pantalla.dart';
import '../servicios/perfil_servicio.dart';
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
        // La llave por usuario hace que, si entra otra persona, se vuelva a
        // consultar su onboarding.
        return _PuertaOnboarding(key: ValueKey(sesion.user.id));
      },
    );
  }
}

/// Con sesión iniciada: muestra el onboarding la primera vez (RF-GIA-05)
/// y después la app.
class _PuertaOnboarding extends StatefulWidget {
  const _PuertaOnboarding({super.key});

  @override
  State<_PuertaOnboarding> createState() => _PuertaOnboardingState();
}

class _PuertaOnboardingState extends State<_PuertaOnboarding> {
  late final Future<bool> _completo = PerfilServicio().onboardingCompleto();
  bool _terminado = false;

  @override
  Widget build(BuildContext context) {
    if (_terminado) return const Inicio();

    return FutureBuilder<bool>(
      future: _completo,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          // No se bloquea la app por no poder leer esta bandera.
          debugPrint('Error leyendo el onboarding: ${snap.error}');
        }
        if (snap.data ?? true) return const Inicio();

        return OnboardingPantalla(
          alTerminar: () {
            setState(() {
              _terminado = true;
            });
          },
        );
      },
    );
  }
}
