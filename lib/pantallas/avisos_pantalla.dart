import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../core/tema.dart';
import '../modelos/notificacion.dart';
import '../servicios/avisos_estado.dart';
import '../servicios/eventos_servicio.dart';
import '../widgets/aviso_sin_conexion.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/pantalla_interna.dart';
import 'detalle_pantalla.dart';

/// Bandeja de avisos (RF-EU-07): cancelaciones, eventos sin cupos y eventos
/// guardados que empiezan pronto. Al tocar un aviso se marca como leído y se
/// abre el detalle del evento.
class AvisosPantalla extends StatefulWidget {
  const AvisosPantalla({super.key});

  @override
  State<AvisosPantalla> createState() => _AvisosPantallaState();
}

class _AvisosPantallaState extends State<AvisosPantalla> {
  final _estado = AvisosEstado.instancia;
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    _estado.sincronizar();
  }

  Future<void> _refrescar() => _estado.sincronizar();

  Future<void> _marcarTodos() async {
    final ok = await _estado.marcarTodosLeidos();
    if (!ok && mounted) _avisarError();
  }

  void _avisarError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No pudimos completar la acción. Inténtalo de nuevo.'),
      ),
    );
  }

  Future<void> _abrir(Notificacion aviso) async {
    if (_abriendo) return;
    setState(() {
      _abriendo = true;
    });
    try {
      // Si no se puede marcar, igual se abre el evento.
      await _estado.marcarLeido(aviso.id);
      final catalogo = await EventosServicio().cargar();
      if (!mounted) return;
      final evento =
          catalogo.eventos.where((e) => e.id == aviso.eventoId).firstOrNull;
      if (evento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese evento ya no está disponible.')),
        );
        return;
      }
      abrirDetalle(context, evento);
    } catch (e) {
      debugPrint('Error abriendo el evento del aviso: $e');
      if (mounted) _avisarError();
    } finally {
      if (mounted) {
        setState(() {
          _abriendo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _estado,
      builder: (context, _) {
        return PantallaInterna(
          titulo: 'Avisos',
          acciones: [
            if (_estado.noLeidos > 0)
              TextButton(
                onPressed: _marcarTodos,
                child: const Text('Marcar leídos'),
              ),
            const SizedBox(width: 6),
          ],
          child: Column(
            children: [
              const AvisoSinConexion(),
              Expanded(child: _cuerpo()),
            ],
          ),
        );
      },
    );
  }

  Widget _cuerpo() {
    if (!_estado.cargado) {
      if (_estado.hayError) {
        return EstadoVacio(
          icono: Icons.wifi_off,
          titulo: 'No pudimos cargar tus avisos',
          mensaje: 'Revisa tu conexión e inténtalo de nuevo.',
          textoBoton: 'Reintentar',
          alPresionar: _refrescar,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final avisos = _estado.avisos;
    if (avisos.isEmpty) {
      return RefreshIndicator(
        color: Paleta.amarillo,
        backgroundColor: Paleta.noche2,
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EstadoVacio(
              icono: Icons.notifications_none,
              titulo: 'Sin avisos por ahora',
              mensaje:
                  'Cuando un evento que guardaste se cancele, se quede sin cupos o esté por empezar, te lo contamos aquí.',
            ),
          ],
        ),
      );
    }

    final ahora = DateTime.now();
    return RefreshIndicator(
      color: Paleta.amarillo,
      backgroundColor: Paleta.noche2,
      onRefresh: _refrescar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        itemCount: avisos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _FilaAviso(
          aviso: avisos[i],
          ahora: ahora,
          alPresionar: () => _abrir(avisos[i]),
        ),
      ),
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({
    required this.aviso,
    required this.ahora,
    required this.alPresionar,
  });

  final Notificacion aviso;
  final DateTime ahora;
  final VoidCallback alPresionar;

  (IconData, Color) get _visual => switch (aviso.tipo) {
        'cancelacion' => (Icons.event_busy_outlined, Paleta.fucsia),
        'sin_cupos' => (Icons.block_outlined, Paleta.naranja),
        _ => (Icons.schedule_outlined, Paleta.amarillo),
      };

  @override
  Widget build(BuildContext context) {
    final (icono, color) = _visual;
    final sinLeer = !aviso.leida;

    return Semantics(
      button: true,
      label: '${sinLeer ? 'Sin leer. ' : ''}${aviso.mensaje}',
      excludeSemantics: true,
      child: Material(
        color: sinLeer ? Paleta.noche3 : Paleta.noche2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.md),
          side: BorderSide(color: sinLeer ? color : Paleta.borde),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radios.md),
          ),
          onTap: alPresionar,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Paleta.noche,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, size: 20, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aviso.mensaje,
                        style: Tipografia.ui(
                          14,
                          peso: sinLeer ? FontWeight.w700 : FontWeight.w500,
                          altura: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        haceCuanto(aviso.creadaEn, ahora),
                        style: Tipografia.ui(12, color: Paleta.papelMut),
                      ),
                    ],
                  ),
                ),
                if (sinLeer)
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 6),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
