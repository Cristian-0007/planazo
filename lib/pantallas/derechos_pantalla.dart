import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../modelos/solicitud_datos.dart';
import '../servicios/solicitudes_servicio.dart';
import '../widgets/chip_filtro.dart';
import '../widgets/pantalla_interna.dart';

/// Canal para que el titular pida conocer, actualizar, corregir o eliminar
/// sus datos personales (RF-CGD-01, CU-21). Cada solicitud queda guardada con
/// su fecha límite de respuesta.
class DerechosPantalla extends StatefulWidget {
  const DerechosPantalla({super.key});

  @override
  State<DerechosPantalla> createState() => _DerechosPantallaState();
}

class _DerechosPantallaState extends State<DerechosPantalla> {
  final _servicio = SolicitudesServicio();
  final _formKey = GlobalKey<FormState>();
  final _detalle = TextEditingController();

  late Future<List<SolicitudDatos>> _solicitudes;
  String _tipo = TipoSolicitud.todos.first.clave;
  bool _enviando = false;
  String? _mensaje;
  bool _mensajeEsError = true;

  @override
  void initState() {
    super.initState();
    _solicitudes = _servicio.listar();
  }

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _solicitudes = _servicio.listar();
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _mensaje = null;
    });
    try {
      await _servicio.crear(tipo: _tipo, detalle: _detalle.text);
      if (!mounted) return;
      _detalle.clear();
      final plazo = TipoSolicitud.de(_tipo).diasHabiles;
      setState(() {
        _mensajeEsError = false;
        _mensaje =
            'Recibimos tu solicitud. Te responderemos en máximo $plazo días hábiles.';
        _solicitudes = _servicio.listar();
      });
    } on PostgrestException catch (e) {
      debugPrint('Error creando la solicitud: $e');
      if (!mounted) return;
      setState(() {
        _mensajeEsError = true;
        // El trigger de la base de datos avisa cuando hay demasiadas abiertas.
        _mensaje = e.code == 'P0001'
            ? e.message
            : 'No pudimos enviar tu solicitud. Inténtalo de nuevo.';
      });
    } catch (e) {
      debugPrint('Error creando la solicitud: $e');
      if (!mounted) return;
      setState(() {
        _mensajeEsError = true;
        _mensaje =
            'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = TipoSolicitud.de(_tipo);

    return PantallaInterna(
      titulo: 'Mis derechos',
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(
            'Como titular de tus datos personales puedes pedirnos que te los mostremos, los actualicemos, los corrijamos o los eliminemos.',
            style: Tipografia.ui(14, color: Paleta.papelMut, altura: 1.5),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TipoSolicitud.todos)
                      ChipFiltro(
                        etiqueta: t.titulo,
                        activo: t.clave == _tipo,
                        alPresionar: _enviando
                            ? () {}
                            : () {
                                setState(() {
                                  _tipo = t.clave;
                                });
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${tipo.descripcion} Plazo de respuesta: ${tipo.diasHabiles} días hábiles.',
                  style: Tipografia.ui(13, color: Paleta.papelMut, altura: 1.4),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _detalle,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoracionCampo(etiqueta: 'Cuéntanos qué necesitas'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 10) return 'Escribe al menos 10 caracteres.';
                    return null;
                  },
                ),
                if (_mensaje != null) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _mensaje!,
                      style: Tipografia.ui(
                        14,
                        peso: FontWeight.w600,
                        altura: 1.4,
                        color: _mensajeEsError ? Paleta.fucsia : Paleta.menta,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Paleta.noche,
                          ),
                        )
                      : const Text('Enviar solicitud'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Mis solicitudes',
            style: Tipografia.display(22, peso: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<SolicitudDatos>>(
            future: _solicitudes,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                debugPrint('Error cargando solicitudes: ${snap.error}');
                return Column(
                  children: [
                    Text(
                      'No pudimos cargar tus solicitudes.',
                      style: Tipografia.ui(14, color: Paleta.papelMut),
                    ),
                    TextButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                );
              }
              final lista = snap.data ?? const <SolicitudDatos>[];
              if (lista.isEmpty) {
                return Text(
                  'Todavía no has hecho ninguna solicitud.',
                  style: Tipografia.ui(14, color: Paleta.papelMut),
                );
              }
              return Column(
                children: [
                  for (final s in lista) ...[
                    _TarjetaSolicitud(solicitud: s),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({required this.solicitud});

  final SolicitudDatos solicitud;

  String _fecha(DateTime f) => '${f.day} ${mesCorto(f)} ${f.year}';

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final limite = s.responderAntesDe;
    final respuesta = s.respuesta?.trim() ?? '';
    final color = switch (s.estado) {
      'resuelta' => Paleta.menta,
      'rechazada' => Paleta.fucsia,
      _ => Paleta.amarillo,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Paleta.noche2,
        borderRadius: BorderRadius.circular(Radios.md),
        border: Border.all(color: Paleta.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  TipoSolicitud.de(s.tipo).titulo,
                  style: Tipografia.ui(15, peso: FontWeight.w700),
                ),
              ),
              Text(
                textoEstadoSolicitud(s.estado),
                style: Tipografia.ui(13, peso: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enviada el ${_fecha(s.creadaEn)}'
            '${s.abierta && limite != null ? ' · Respuesta antes del ${_fecha(limite)}' : ''}',
            style: Tipografia.ui(12, color: Paleta.papelMut),
          ),
          const SizedBox(height: 8),
          Text(s.detalle, style: Tipografia.ui(13, altura: 1.4)),
          if (respuesta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Respuesta: $respuesta',
              style: Tipografia.ui(13, color: Paleta.menta, altura: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
