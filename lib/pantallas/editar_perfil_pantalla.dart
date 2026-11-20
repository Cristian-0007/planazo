import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../core/validaciones.dart';
import '../modelos/ciudad.dart';
import '../servicios/perfil_servicio.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/fila_ajuste.dart';
import '../widgets/pantalla_interna.dart';
import 'ciudad_pantalla.dart';

/// Editar nombre, teléfono de contacto y ciudad (RF-PU-01).
/// El correo y la contraseña se cambian en "Cuenta y seguridad".
class EditarPerfilPantalla extends StatefulWidget {
  const EditarPerfilPantalla({super.key});

  @override
  State<EditarPerfilPantalla> createState() => _EditarPerfilPantallaState();
}

class _EditarPerfilPantallaState extends State<EditarPerfilPantalla> {
  final _servicio = PerfilServicio();
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();

  bool _cargando = true;
  bool _error = false;
  bool _guardando = false;
  String? _ciudadId;
  String? _ciudadNombre;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await _servicio.cargar();
      if (!mounted) return;
      if (perfil == null) throw StateError('No se encontró el perfil.');
      _nombre.text = perfil.nombre;
      _telefono.text = perfil.telefono ?? '';
      setState(() {
        _ciudadId = perfil.ciudadId;
        _ciudadNombre = perfil.ciudadNombre;
        _cargando = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Error cargando el perfil: $e');
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

  Future<void> _elegirCiudad() async {
    final ciudad = await Navigator.of(context).push<Ciudad>(
      MaterialPageRoute<Ciudad>(
        builder: (_) => CiudadPantalla(seleccionadaId: _ciudadId),
      ),
    );
    if (ciudad == null || !mounted) return;
    setState(() {
      _ciudadId = ciudad.id;
      _ciudadNombre = ciudad.nombre;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
    });
    try {
      await _servicio.guardarDatos(
        nombre: _nombre.text,
        telefono: normalizarTelefono(_telefono.text),
        ciudadId: _ciudadId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error guardando el perfil: $e');
      if (!mounted) return;
      setState(() {
        _guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar tus datos. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaInterna(titulo: 'Datos personales', child: _cuerpo());
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return EstadoVacio(
        icono: Icons.wifi_off,
        titulo: 'No pudimos cargar tus datos',
        mensaje: 'Revisa tu conexión e inténtalo de nuevo.',
        textoBoton: 'Reintentar',
        alPresionar: _reintentar,
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          TextFormField(
            controller: _nombre,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: decoracionCampo(
              etiqueta: 'Nombre',
              icono: Icons.person_outline,
            ),
            validator: validarNombre,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: decoracionCampo(
              etiqueta: 'Teléfono de contacto (opcional)',
              icono: Icons.phone_outlined,
            ),
            validator: validarTelefono,
          ),
          const SizedBox(height: 14),
          FilaAjuste(
            icono: Icons.location_on_outlined,
            titulo: 'Ciudad',
            subtitulo: _ciudadNombre ?? 'Sin elegir',
            alPresionar: _elegirCiudad,
          ),
          const SizedBox(height: 28),
          FilledButton(
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
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
