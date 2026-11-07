import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/puerta_sesion.dart';
import 'core/config.dart';
import 'core/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseClave,
  );
  runApp(const PlanazoApp());
}

class PlanazoApp extends StatelessWidget {
  const PlanazoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planazo',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const PuertaSesion(),
    );
  }
}
