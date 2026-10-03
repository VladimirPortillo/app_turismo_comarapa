import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/lugar.dart';
import '../models/turismo_tipo.dart';
import '../screens/place_detail_screen.dart' show MountainHeroPainter;
import '../widgets/resenas_section.dart';
import 'web_components.dart';
import 'web_widgets.dart';

/// Detalle de un lugar para la versión web de escritorio:
/// galería tipo mosaico + contenido en dos columnas.
class WebPlaceDetailScreen extends StatefulWidget {
  const WebPlaceDetailScreen({super.key, required this.lugar});

  final Lugar lugar;

  @override
  State<WebPlaceDetailScreen> createState() => _WebPlaceDetailScreenState();
}

class _WebPlaceDetailScreenState extends State<WebPlaceDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  // Coordenadas por defecto (Comarapa) si el lugar no tiene ubicación asignada.
  static const LatLng _defaultPunto = LatLng(-17.9144, -64.5319);

  Lugar get _lugar => widget.lugar;

  LatLng get _punto {
    final lat = _lugar.latitud;
    final lng = _lugar.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return _defaultPunto;
  }

  String get _costoTexto {
    final costo = _lugar.costoEntrada;
    if (costo <= 0) return 'Gratis';
    final texto =
        costo == costo.roundToDouble() ? costo.toInt().toString() : '$costo';
    return 'Bs $texto';
  }

  @override
  Widget build(BuildContext context) {
    final categoria = _lugar.categoriaNombre?.trim();
    final direccion = _lugar.direccionReferencia?.trim();

    return WebDetailScaffold(
      seccion: 'Lugares',
      titulo: _lugar.nombre,
      encabezado: WebDetailHeader(
        categoria: (categoria == null || categoria.isEmpty) ? 'Natural' : categoria,
        nombre: _lugar.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          if (direccion != null && direccion.isNotEmpty)
            WebIconText(icono: Icons.place_outlined, texto: direccion),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _lugar.imagenes,
        respaldo: _respaldo(),
        ancho: ancho,
      ),
      principal: _buildColumnaPrincipal(),
      lateral: _buildColumnaLateral(),
    );
  }

  Widget _respaldo() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4D36), Color(0xFF26674B), Color(0xFF357A59)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(painter: MountainHeroPainter()),
    );
  }

  Widget _buildColumnaPrincipal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebDescripcion(
          titulo: 'Descripción',
          texto: _lugar.descripcion,
          vacio: 'Este lugar todavía no tiene descripción.',
        ),
        if (_lugar.id != null)
          ResenasSection(
            entidad: 'lugar',
            entidadId: _lugar.id!,
            onResumenActualizado: (promedio, total) {
              setState(() {
                _promedioResenas = promedio;
                _totalResenas = total;
              });
            },
          ),
      ],
    );
  }

  Widget _buildColumnaLateral() {
    return Column(
      children: [
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Información de la visita'),
              const SizedBox(height: 16),
              WebDato(
                icono: Icons.access_time_outlined,
                titulo: 'Duración',
                valor: duracionLabel(_lugar.tiempoVisitaMin),
              ),
              WebDato(
                icono: Icons.terrain_outlined,
                titulo: 'Dificultad',
                valor: dificultadLabel(_lugar.dificultad),
              ),
              WebDato(
                icono: Icons.calendar_today_outlined,
                titulo: 'Mejor época',
                valor: (_lugar.mejorEpoca?.trim().isNotEmpty ?? false)
                    ? _lugar.mejorEpoca!
                    : 'Todo el año',
              ),
              WebDato(
                icono: Icons.payments_outlined,
                titulo: 'Entrada',
                valor: _costoTexto,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        WebUbicacionCard(
          titulo: 'Ubicación',
          nombreDestino: _lugar.nombre,
          punto: _punto,
          detalle: _lugar.direccionReferencia,
        ),
      ],
    );
  }
}
