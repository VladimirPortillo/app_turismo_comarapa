import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/hotel.dart';
import '../widgets/resenas_section.dart';
import 'web_components.dart';
import 'web_hotels_screen.dart' show iconoServicio, preciosHotel;
import 'web_theme.dart';
import 'web_widgets.dart';

/// Detalle de un hospedaje para la versión web de escritorio.
class WebHotelDetailScreen extends StatefulWidget {
  const WebHotelDetailScreen({super.key, required this.hotel});

  final Hotel hotel;

  @override
  State<WebHotelDetailScreen> createState() => _WebHotelDetailScreenState();
}

class _WebHotelDetailScreenState extends State<WebHotelDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  Hotel get _h => widget.hotel;

  LatLng? get _punto {
    final lat = _h.latitud;
    final lng = _h.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return null;
  }

  void _contactar() {
    final contacto = textoONulo(_h.contactoReservas);
    if (contacto == null) return;
    showWebContactDialog(
      context,
      nombre: _h.nombre,
      contacto: contacto,
      rol: 'Recepción / reservas',
      icono: Icons.hotel_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final direccion = textoONulo(_h.direccionReferencia);

    return WebDetailScaffold(
      seccion: 'Hoteles',
      titulo: _h.nombre,
      encabezado: WebDetailHeader(
        categoria: textoONulo(_h.categoriaNombre) ?? 'Hotel',
        nombre: _h.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          if (direccion != null)
            WebIconText(icono: Icons.place_outlined, texto: direccion),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _h.imagenes,
        respaldo: const WebIconoRespaldo(icono: Icons.hotel),
        ancho: ancho,
      ),
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebDescripcion(
            titulo: 'Sobre el hospedaje',
            texto: _h.descripcion,
            vacio: 'Este hospedaje todavía no tiene descripción.',
          ),
          if (_h.servicios.isNotEmpty) _buildServicios(),
          if (_h.id != null)
            ResenasSection(
              entidad: 'hotel',
              entidadId: _h.id!,
              onResumenActualizado: (promedio, total) {
                setState(() {
                  _promedioResenas = promedio;
                  _totalResenas = total;
                });
              },
            ),
        ],
      ),
      lateral: _buildLateral(direccion),
    );
  }

  Widget _buildServicios() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebSectionTitle('Servicios y comodidades'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in _h.servicios)
                Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(iconoServicio(s), color: WebTheme.verde, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLateral(String? direccion) {
    final precio = preciosHotel(_h);
    final contacto = textoONulo(_h.contactoReservas);
    final punto = _punto;

    return Column(
      children: [
        WebReservaCard(
          etiquetaPrecio: 'Precio por noche',
          precio: precio,
          rolContacto: 'Contacto de reservas',
          nombreContacto: contacto,
          iconoContacto: Icons.room_service_outlined,
          textoBoton: 'Contactar recepción',
          onContactar: contacto != null ? _contactar : null,
        ),
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Información'),
              const SizedBox(height: 16),
              WebDato(
                icono: Icons.apartment_outlined,
                titulo: 'Tipo',
                valor: textoONulo(_h.categoriaNombre) ?? 'Hotel',
              ),
              if (precio.isNotEmpty)
                WebDato(
                  icono: Icons.payments_outlined,
                  titulo: 'Precios',
                  valor: precio,
                  colorValor: const Color(0xFF26674B),
                ),
              if (_h.servicios.isNotEmpty)
                WebDato(
                  icono: Icons.room_service_outlined,
                  titulo: 'Servicios',
                  valor: '${_h.servicios.length} incluidos',
                ),
              if (_h.calificacionPromedio > 0)
                WebDato(
                  icono: Icons.star_outline,
                  titulo: 'Calificación',
                  valor: _h.calificacionPromedio.toStringAsFixed(1),
                ),
            ],
          ),
        ),
        if (punto != null) ...[
          const SizedBox(height: 20),
          WebUbicacionCard(
            titulo: 'Ubicación',
            nombreDestino: _h.nombre,
            punto: punto,
            detalle: direccion,
          ),
        ],
      ],
    );
  }
}
