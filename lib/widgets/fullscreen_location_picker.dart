import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../services/location_service.dart';

/// Pantalla completa interactiva para seleccionar una ubicación geográfica.
/// Permite al usuario tocar cualquier parte del mapa para mover el pin,
/// hacer zoom, centrarse en el GPS del dispositivo o centrarse en el marcador,
/// y confirmar la coordenada seleccionada retornando el [LatLng].
class FullscreenLocationPicker extends StatefulWidget {
  const FullscreenLocationPicker({
    super.key,
    required this.initialLocation,
    this.title = 'Seleccionar ubicación',
    this.subtitle,
  });

  final LatLng initialLocation;
  final String title;
  final String? subtitle;

  /// Método estático conveniente para abrir el selector a pantalla completa.
  static Future<LatLng?> pick({
    required BuildContext context,
    required LatLng initialLocation,
    String title = 'Seleccionar ubicación',
    String? subtitle,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenLocationPicker(
          initialLocation: initialLocation,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  State<FullscreenLocationPicker> createState() =>
      _FullscreenLocationPickerState();
}

class _FullscreenLocationPickerState extends State<FullscreenLocationPicker> {
  late LatLng _currentLocation;
  late final MapController _mapController;
  bool _obteniendoUbicacion = false;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _obtenerMiUbicacion() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      const service = LocationService();
      final posicion = await service.getCurrentPosition();
      final nuevaPos = LatLng(posicion.latitude, posicion.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = nuevaPos;
      });
      _mapController.move(nuevaPos, 16.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida del GPS del dispositivo.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo obtener la ubicación: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  void _zoomIn() {
    _currentZoom = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _mapController.move(_currentLocation, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentLocation, _currentZoom);
  }

  void _centrarEnMarcador() {
    _mapController.move(_currentLocation, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF26674B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3D28),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.subtitle ?? 'Toca el mapa para reubicar el pin',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFB8D5C8)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_currentLocation),
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
            label: const Text(
              'Listo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Mapa interactivo a pantalla completa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _currentZoom,
              onTap: (tapPosition, point) {
                setState(() => _currentLocation = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      size: 48,
                      color: Color(0xFFDC2626), // Rojo llamativo o verde
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Banner superior con instrucciones
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 16, color: primaryColor),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Toca en el mapa para ubicar el marcador',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5A3F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botones flotantes laterales (Zoom, recentrar, GPS)
          Positioned(
            right: 16,
            top: 70,
            child: Column(
              children: [
                _buildFloatingAction(
                  icon: Icons.add,
                  tooltip: 'Acercar',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildFloatingAction(
                  icon: Icons.remove,
                  tooltip: 'Alejar',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 12),
                _buildFloatingAction(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Centrar en el marcador',
                  onTap: _centrarEnMarcador,
                ),
                const SizedBox(height: 8),
                _buildFloatingAction(
                  icon: _obteniendoUbicacion
                      ? null
                      : Icons.my_location,
                  child: _obteniendoUbicacion
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : null,
                  tooltip: 'Mi ubicación actual (GPS)',
                  onTap: _obteniendoUbicacion ? null : _obtenerMiUbicacion,
                ),
              ],
            ),
          ),

          // Panel inferior de confirmación
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle superior sutil
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Coordenadas actuales
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5EFEA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.pin_drop,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coordenadas seleccionadas:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Botón confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pop(_currentLocation),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Confirmar esta ubicación',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAction({
    IconData? icon,
    Widget? child,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            child: child ??
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF26674B),
                ),
          ),
        ),
      ),
    );
  }
}
