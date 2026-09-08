import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../services/location_service.dart';
import '../services/routing_service.dart';

/// Hoja de mapa a pantalla completa reutilizable, con dos acciones: mostrar
/// la ubicación actual del usuario ("Mi ubicación") y trazar la ruta hacia
/// [destino] ("Cómo llegar"), usando el servidor demo público de OSRM.
/// Se usa tanto para el detalle de un lugar como para la ubicación general
/// del municipio.
class FullMapSheet extends StatefulWidget {
  const FullMapSheet({
    super.key,
    required this.titulo,
    required this.destino,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final LatLng destino;

  @override
  State<FullMapSheet> createState() => _FullMapSheetState();
}

class _FullMapSheetState extends State<FullMapSheet> {
  final MapController _mapController = MapController();

  LatLng? _miUbicacion;
  List<LatLng> _rutaPuntos = const <LatLng>[];
  bool _cargandoUbicacion = false;
  bool _cargandoRuta = false;
  String? _rutaInfoTexto;

  Future<LatLng?> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      final service = context.read<LocationService>();
      final posicion = await service.getCurrentPosition();
      final ubicacion = LatLng(posicion.latitude, posicion.longitude);
      if (mounted) setState(() => _miUbicacion = ubicacion);
      return ubicacion;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener tu ubicación: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  Future<void> _onMiUbicacionTap() async {
    final ubicacion = await _obtenerUbicacion();
    if (ubicacion != null) _ajustarCamara();
  }

  Future<void> _onComoLlegarTap() async {
    final origen = _miUbicacion ?? await _obtenerUbicacion();
    if (origen == null || !mounted) return;

    setState(() {
      _cargandoRuta = true;
      _rutaInfoTexto = null;
    });

    try {
      final routing = context.read<RoutingService>();
      final resultado = await routing.fetchRuta(origen: origen, destino: widget.destino);
      if (!mounted) return;
      setState(() {
        _rutaPuntos = resultado.puntos;
        _rutaInfoTexto = _formatearInfoRuta(resultado);
      });
      _ajustarCamara();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo calcular la ruta: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoRuta = false);
    }
  }

  String _formatearInfoRuta(RutaResultado ruta) {
    final km = ruta.distanciaMetros / 1000;
    final distanciaTexto = km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
    final minutos = (ruta.duracionSegundos / 60).round();
    final duracionTexto =
        minutos >= 60 ? '${(minutos / 60).toStringAsFixed(1)} h' : '$minutos min';
    return '$distanciaTexto · $duracionTexto en auto';
  }

  void _ajustarCamara() {
    final puntos = <LatLng>[
      widget.destino,
      if (_miUbicacion != null) _miUbicacion!,
      ..._rutaPuntos,
    ];
    if (puntos.length < 2) return;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(coordinates: puntos, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {
      // El mapa puede no estar listo todavía; se ignora en ese caso.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C3D28),
                          fontFamily: 'serif',
                        ),
                      ),
                      if (widget.subtitulo != null && widget.subtitulo!.isNotEmpty)
                        Text(
                          widget.subtitulo!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.destino,
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
                    ),
                    if (_rutaPuntos.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _rutaPuntos,
                            color: const Color(0xFF2A7353),
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.destino,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            size: 44,
                            color: Color(0xFF26674B),
                          ),
                        ),
                        if (_miUbicacion != null)
                          Marker(
                            point: _miUbicacion!,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5A3F),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (_rutaInfoTexto != null)
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.route_outlined, size: 16, color: Color(0xFF1B5A3F)),
                            const SizedBox(width: 6),
                            Text(
                              _rutaInfoTexto!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1B5A3F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  right: 16,
                  bottom: 92,
                  child: _buildRoundButton(
                    icon: Icons.my_location,
                    loading: _cargandoUbicacion,
                    onTap: _cargandoUbicacion ? null : _onMiUbicacionTap,
                  ),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _cargandoRuta ? null : _onComoLlegarTap,
                      icon: _cargandoRuta
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.directions, size: 20),
                      label: const Text(
                        'Cómo llegar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26674B),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5A3F)),
              )
            : Icon(icon, color: const Color(0xFF1B5A3F), size: 22),
      ),
    );
  }
}
