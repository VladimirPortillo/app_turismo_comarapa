import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/lugar.dart';
import '../models/turismo_tipo.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Lugar lugar;

  const PlaceDetailScreen({
    super.key,
    required this.lugar,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isFavorite = false;

  // Coordenadas por defecto (Comarapa) si el lugar no tiene ubicación asignada
  static const double _defaultLat = -17.9144;
  static const double _defaultLng = -64.5319;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  LatLng get _locationPoint {
    final lat = widget.lugar.latitud;
    final lng = widget.lugar.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  String get _categoriaLabel {
    final cat = widget.lugar.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'NATURAL';
  }

  String get _tiempoTexto {
    final minutos = widget.lugar.tiempoVisitaMin;
    if (minutos == null || minutos <= 0) return '2 horas';
    if (minutos < 60) return '$minutos min';
    final horas = minutos / 60;
    final horasTexto =
        horas == horas.roundToDouble() ? horas.toInt().toString() : horas.toStringAsFixed(1);
    return '$horasTexto ${horas == 1 ? "hora" : "horas"}';
  }

  String get _dificultadTexto {
    final dif = widget.lugar.dificultad;
    if (dif.isEmpty) return 'Fácil';
    return dificultadLabel(dif);
  }

  String get _mejorEpocaTexto {
    final epoca = widget.lugar.mejorEpoca;
    if (epoca != null && epoca.trim().isNotEmpty) {
      return epoca;
    }
    return 'Abr-Oct';
  }

  String get _descripcionTexto {
    final desc = widget.lugar.descripcion;
    if (desc.trim().isNotEmpty) {
      return desc;
    }
    return 'Un mirador natural donde crecen decenas de especies de cactáceas junto a formaciones '
        'rocosas únicas. Es uno de los atractivos más fotografiados del municipio y el punto de partida '
        'para varias caminatas cortas con vista a los valles y serranías de Comarapa.';
  }

  void _onShare() {
    Clipboard.setData(ClipboardData(
      text: '${widget.lugar.nombre} - Descubre Comarapa Turismo',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace de "${widget.lugar.nombre}" copiado'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFullMap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
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
                                widget.lugar.nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C3D28),
                                  fontFamily: 'serif',
                                ),
                              ),
                              if (widget.lugar.direccionReferencia != null &&
                                  widget.lugar.direccionReferencia!.isNotEmpty)
                                Text(
                                  widget.lugar.direccionReferencia!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _locationPoint,
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _locationPoint,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                size: 44,
                                color: Color(0xFF26674B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.lugar.imagenes;
    final totalSlides = imagenes.isNotEmpty ? imagenes.length : 3;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Stack(
        children: [
          // Contenido principal scrollable
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con carrusel/ilustración
                _buildHeroHeader(totalSlides),

                // Tarjeta de información con bordes superiores redondeados
                _buildContentCard(),
              ],
            ),
          ),

          // Botón fijo inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(int totalSlides) {
    final imagenes = widget.lugar.imagenes;

    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carrusel de imágenes o ilustración vectorial
          if (imagenes.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: imagenes.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final url = imagenes[index];
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackIllustration(),
                );
              },
            )
          else
            PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _buildFallbackIllustration(),
            ),

          // Indicador de página (píldora alargada para activo, puntos pequeños para inactivos)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlides, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Barra superior de navegación con botones circulares
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Volver
                  _buildCircleButton(
                    icon: Icons.chevron_left,
                    iconSize: 26,
                    onTap: () => Navigator.of(context).pop(),
                  ),

                  // Acciones superiores: Favorito y Compartir
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                        iconColor: _isFavorite ? const Color(0xFFE53935) : Colors.black87,
                        iconSize: 22,
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFavorite
                                    ? 'Añadido a tus favoritos'
                                    : 'Eliminado de tus favoritos',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        icon: Icons.share_outlined,
                        iconSize: 20,
                        onTap: _onShare,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B4D36),
            Color(0xFF26674B),
            Color(0xFF357A59),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: MountainHeroPainter(),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 24,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF9F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F0E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categoriaLabel,
                style: const TextStyle(
                  color: Color(0xFF1B5A3F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del Lugar
            Text(
              widget.lugar.nombre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Puntuación y Reseñas
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < 4 ? Icons.star : Icons.star_border,
                    size: 20,
                    color: const Color(0xFFE59819),
                  );
                }),
                const SizedBox(width: 8),
                const Text(
                  '4.2 · 86 reseñas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3 Tarjetas de información rápida
            _buildQuickInfoRow(),
            const SizedBox(height: 28),

            // Sección: Descripción
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _descripcionTexto,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),

            // Sección: Ubicación
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 12),

            // Mini mapa de preview
            _buildMiniMap(),

            if (widget.lugar.direccionReferencia != null &&
                widget.lugar.direccionReferencia!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: Color(0xFF1B5A3F)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.lugar.direccionReferencia!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_outlined,
            title: _tiempoTexto,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.terrain_outlined,
            title: _dificultadTexto,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_today_outlined,
            title: _mejorEpocaTexto,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF1B5A3F),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFE2EFE7),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _locationPoint,
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _locationPoint,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        size: 38,
                        color: Color(0xFF26674B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Capa suave para toque
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openFullMap(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _openFullMap(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26674B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 22, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Ver en el mapa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter que dibuja la ilustración vectorial de montañas en tonos verdes,
/// reproduciendo exactamente el fondo visual de la maqueta cuando no hay fotografía cargada.
class MountainHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF1B4D36).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF2A7252).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Silueta de montaña posterior
    final path1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.55, size.height * 0.82)
      ..lineTo(size.width * 0.78, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    // Silueta de montaña frontal
    final path2 = Path()
      ..moveTo(0, size.height * 0.88)
      ..lineTo(size.width * 0.22, size.height * 0.60)
      ..lineTo(size.width * 0.42, size.height * 0.79)
      ..lineTo(size.width * 0.65, size.height * 0.54)
      ..lineTo(size.width * 0.88, size.height * 0.84)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
