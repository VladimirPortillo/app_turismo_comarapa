import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/evento.dart';
import '../widgets/resenas_section.dart';
import 'web_components.dart';
import 'web_events_screen.dart'
    show WebFechaBadge, eventoFinalizado, kMesesLargos, periodicidadTexto;
import 'web_theme.dart';
import 'web_widgets.dart';

/// Detalle de un evento para la versión web de escritorio.
class WebEventDetailScreen extends StatefulWidget {
  const WebEventDetailScreen({super.key, required this.evento});

  final Evento evento;

  @override
  State<WebEventDetailScreen> createState() => _WebEventDetailScreenState();
}

class _WebEventDetailScreenState extends State<WebEventDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  Evento get _e => widget.evento;

  LatLng? get _punto {
    final lat = _e.latitud;
    final lng = _e.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return null;
  }

  /// "Del 21 al 23 de marzo", "30 de marzo al 2 de abril" o "21 de marzo".
  String get _fechasTexto {
    final inicio = _e.fechaInicio;
    final fin = _e.fechaFin;
    final mes = kMesesLargos[inicio.month - 1];
    if (fin != null &&
        (fin.day != inicio.day ||
            fin.month != inicio.month ||
            fin.year != inicio.year)) {
      if (fin.month == inicio.month && fin.year == inicio.year) {
        return 'Del ${inicio.day} al ${fin.day} de $mes';
      }
      return '${inicio.day} de $mes al ${fin.day} de ${kMesesLargos[fin.month - 1]}';
    }
    return '${inicio.day} de $mes';
  }

  int get _diasDuracion {
    final fin = _e.fechaFin;
    if (fin == null) return 1;
    return fin.difference(_e.fechaInicio).inDays + 1;
  }

  /// Estado del evento respecto a hoy: cuenta regresiva, en curso o finalizado.
  ({String texto, Color color, IconData icono}) get _estado {
    final hoy = DateTime.now();
    final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);
    final inicio = DateTime(
      _e.fechaInicio.year,
      _e.fechaInicio.month,
      _e.fechaInicio.day,
    );
    if (eventoFinalizado(_e)) {
      return (
        texto: 'Este evento ya finalizó',
        color: Colors.grey.shade600,
        icono: Icons.history,
      );
    }
    final dias = inicio.difference(hoySolo).inDays;
    if (dias <= 0) {
      return (
        texto: dias == 0 ? '¡Es hoy!' : 'En curso',
        color: const Color(0xFF16A34A),
        icono: Icons.celebration_outlined,
      );
    }
    return (
      texto: dias == 1 ? 'Falta 1 día' : 'Faltan $dias días',
      color: const Color(0xFFB45309),
      icono: Icons.hourglass_bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodicidad = periodicidadTexto(_e);

    return WebDetailScaffold(
      seccion: 'Eventos',
      titulo: _e.nombre,
      encabezado: WebDetailHeader(
        categoria: textoONulo(_e.categoriaNombre) ?? 'Evento',
        nombre: _e.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          WebIconText(icono: Icons.calendar_month, texto: _fechasTexto),
          if (periodicidad != null)
            WebIconText(icono: Icons.repeat, texto: periodicidad),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _e.imagenes,
        respaldo: const WebIconoRespaldo(icono: Icons.celebration),
        ancho: ancho,
      ),
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebDescripcion(
            titulo: 'Sobre el evento',
            texto: _e.descripcion,
            vacio: 'Este evento todavía no tiene descripción.',
          ),
          if (_e.id != null)
            ResenasSection(
              entidad: 'evento',
              entidadId: _e.id!,
              onResumenActualizado: (promedio, total) {
                setState(() {
                  _promedioResenas = promedio;
                  _totalResenas = total;
                });
              },
            ),
        ],
      ),
      lateral: _buildLateral(periodicidad),
    );
  }

  Widget _buildLateral(String? periodicidad) {
    final estado = _estado;
    final punto = _punto;
    final dias = _diasDuracion;

    return Column(
      children: [
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FECHA DEL EVENTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  WebFechaBadge(evento: _e, grande: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fechasTexto,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WebTheme.verdeOscuro,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_e.fechaInicio.year}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: estado.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(estado.icono, size: 18, color: estado.color),
                    const SizedBox(width: 8),
                    Text(
                      estado.texto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: estado.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Detalles'),
              const SizedBox(height: 16),
              WebDato(
                icono: Icons.event_outlined,
                titulo: 'Inicio',
                valor: '${_e.diaFormateado} ${_e.mesAbreviado}',
              ),
              if (_e.fechaFin != null)
                WebDato(
                  icono: Icons.date_range_outlined,
                  titulo: 'Duración',
                  valor: dias > 1 ? '$dias días' : '1 día',
                ),
              if (periodicidad != null)
                WebDato(
                  icono: Icons.repeat_outlined,
                  titulo: 'Frecuencia',
                  valor: periodicidad,
                ),
              if (textoONulo(_e.categoriaNombre) != null)
                WebDato(
                  icono: Icons.category_outlined,
                  titulo: 'Tipo',
                  valor: _e.categoriaNombre!.trim(),
                ),
            ],
          ),
        ),
        if (punto != null) ...[
          const SizedBox(height: 20),
          WebUbicacionCard(
            titulo: 'Lugar del evento',
            nombreDestino: _e.nombre,
            punto: punto,
            detalle: 'Comarapa',
          ),
        ],
      ],
    );
  }
}
