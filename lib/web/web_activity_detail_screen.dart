import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/actividad.dart';
import '../models/turismo_tipo.dart';
import '../widgets/resenas_section.dart';
import 'web_activities_screen.dart' show colorDificultad, nivelDificultad;
import 'web_components.dart';
import 'web_widgets.dart';

/// Detalle de una actividad para la versión web de escritorio.
class WebActivityDetailScreen extends StatefulWidget {
  const WebActivityDetailScreen({super.key, required this.actividad});

  final Actividad actividad;

  @override
  State<WebActivityDetailScreen> createState() =>
      _WebActivityDetailScreenState();
}

class _WebActivityDetailScreenState extends State<WebActivityDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  Actividad get _act => widget.actividad;

  /// Solo se muestra el mapa si la actividad tiene coordenadas reales.
  LatLng? get _punto {
    final lat = _act.latitud;
    final lng = _act.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return null;
  }

  void _contactar() {
    final operador = textoONulo(_act.operadorContacto);
    if (operador == null) return;
    showWebContactDialog(
      context,
      nombre: _act.nombre,
      contacto: operador,
      rol: 'Operador / guía',
      icono: Icons.support_agent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final duracion = duracionLabel(_act.duracionMin, vacio: '');
    final temporada = textoONulo(_act.temporada);

    return WebDetailScaffold(
      seccion: 'Actividades',
      titulo: _act.nombre,
      encabezado: WebDetailHeader(
        categoria: textoONulo(_act.categoriaNombre) ?? 'Actividad',
        nombre: _act.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          if (duracion.isNotEmpty)
            WebIconText(icono: Icons.access_time_outlined, texto: duracion),
          if (temporada != null)
            WebIconText(icono: Icons.calendar_month_outlined, texto: temporada),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _act.imagenes,
        respaldo: const WebIconoRespaldo(icono: Icons.hiking),
        ancho: ancho,
      ),
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebDescripcion(
            titulo: 'Descripción de la actividad',
            texto: _act.descripcion,
            vacio: 'Esta actividad todavía no tiene descripción.',
          ),
          if (_act.id != null)
            ResenasSection(
              entidad: 'actividad',
              entidadId: _act.id!,
              onResumenActualizado: (promedio, total) {
                setState(() {
                  _promedioResenas = promedio;
                  _totalResenas = total;
                });
              },
            ),
        ],
      ),
      lateral: _buildLateral(duracion, temporada),
    );
  }

  Widget _buildLateral(String duracion, String? temporada) {
    final precio = precioBs(_act.precioReferencial);
    final operador = textoONulo(_act.operadorContacto);
    final capacidad = _act.capacidadMaxima;
    final punto = _punto;

    return Column(
      children: [
        WebReservaCard(
          etiquetaPrecio: 'Precio referencial',
          precio: precio,
          sufijoPrecio: precio == 'Gratis' ? null : '/ persona',
          rolContacto: 'Operador / guía',
          nombreContacto: operador,
          iconoContacto: Icons.hiking,
          textoBoton: 'Contactar guía',
          onContactar: operador != null ? _contactar : null,
        ),

        // Datos de la actividad (solo los que existen en la BD).
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Detalles'),
              const SizedBox(height: 16),
              if (duracion.isNotEmpty)
                WebDato(
                  icono: Icons.access_time_outlined,
                  titulo: 'Duración',
                  valor: duracion,
                ),
              WebDato(
                icono: Icons.fitness_center_outlined,
                titulo: 'Dificultad',
                valor: dificultadLabel(nivelDificultad(_act.dificultad)),
                colorValor: colorDificultad(_act.dificultad),
              ),
              if (capacidad != null && capacidad > 0)
                WebDato(
                  icono: Icons.people_outline,
                  titulo: 'Capacidad',
                  valor: 'Máx. $capacidad personas',
                ),
              if (temporada != null)
                WebDato(
                  icono: Icons.calendar_month_outlined,
                  titulo: 'Temporada',
                  valor: temporada,
                ),
            ],
          ),
        ),

        if (punto != null) ...[
          const SizedBox(height: 20),
          WebUbicacionCard(
            titulo: 'Punto de partida',
            nombreDestino: _act.nombre,
            punto: punto,
            detalle: 'Punto de encuentro y partida · Comarapa',
          ),
        ],
      ],
    );
  }
}
