import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/hotel.dart';

class HotelDetailScreen extends StatefulWidget {
  final Hotel hotel;

  const HotelDetailScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isFavorite = false;

  // Coordenadas por defecto (Comarapa) si el hotel no tiene ubicación asignada
  static const double _defaultLat = -18.0401;
  static const double _defaultLng = -64.5276;

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
    final lat = widget.hotel.latitud;
    final lng = widget.hotel.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  String get _categoriaLabel {
    final cat = widget.hotel.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'HOTEL';
  }

  String get _precioTexto {
    final min = widget.hotel.precioMin;
    final max = widget.hotel.precioMax;
    if (min != null && max != null) {
      return 'Bs ${min.toInt()} - ${max.toInt()}';
    } else if (min != null) {
      return 'Desde Bs ${min.toInt()}';
    }
    return 'Bs 150 - 250';
  }

  String get _tipoHospedaje {
    return widget.hotel.categoriaNombre ?? 'Hotel';
  }

  String get _descripcionTexto {
    final desc = widget.hotel.descripcion;
    if (desc.trim().isNotEmpty) {
      return desc;
    }
    return 'Acogedor establecimiento en Comarapa diseñado para ofrecer una estadía tranquila '
        'y confortable. Con habitaciones completamente equipadas, hermosas vistas a los valles '
        'y atención personalizada para que disfrutes al máximo de tus vacaciones en la región.';
  }

  List<String> get _amenidadesList {
    if (widget.hotel.servicios.isNotEmpty) {
      return widget.hotel.servicios;
    }
    return ['Wifi gratis', 'Parqueo privado', 'Desayuno incluido', 'Agua caliente', 'Atención 24h'];
  }

  IconData _iconForAmenity(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('wifi')) return Icons.wifi;
    if (a.contains('parqueo') || a.contains('estacionamiento')) return Icons.local_parking;
    if (a.contains('desayuno') || a.contains('café')) return Icons.coffee_outlined;
    if (a.contains('agua') || a.contains('baño')) return Icons.hot_tub_outlined;
    if (a.contains('fogata')) return Icons.local_fire_department_outlined;
    if (a.contains('piscina')) return Icons.pool;
    if (a.contains('aire') || a.contains('clima')) return Icons.ac_unit;
    return Icons.check_circle_outline;
  }

  void _onShare() {
    Clipboard.setData(ClipboardData(
      text: '${widget.hotel.nombre} - Hospedaje en Comarapa Turismo',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace de "${widget.hotel.nombre}" copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final contacto = widget.hotel.contactoReservas?.isNotEmpty == true
        ? widget.hotel.contactoReservas!
        : '+591 3 936 1000';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contacto y Reservas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C3D28),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Comunícate directamente con recepción para consultar disponibilidad de habitaciones en "${widget.hotel.nombre}":',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFC7E2D6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF26674B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hotel_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hotel.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Color(0xFF0C3D28),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contacto,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF26674B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Número copiado. Abriendo canal de reservas...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text(
                    'Llamar / Contactar por WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26674B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                                widget.hotel.nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C3D28),
                                  fontFamily: 'serif',
                                ),
                              ),
                              Text(
                                widget.hotel.direccionReferencia?.isNotEmpty == true
                                    ? widget.hotel.direccionReferencia!
                                    : 'Comarapa, Santa Cruz',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
    final imagenes = widget.hotel.imagenes;
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
    final imagenes = widget.hotel.imagenes;

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

          // Indicador de página animado
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

          // Barra superior con botones circulares
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

                  // Acciones: Favorito y Compartir
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
                                    ? 'Añadido a tus hoteles favoritos'
                                    : 'Eliminado de tus hoteles favoritos',
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
            Color(0xFF0F3924),
            Color(0xFF1B5A3F),
            Color(0xFF2E7D58),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hotel,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.hotel.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
                color: const Color(0xFFE2ECE7),
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

            // Nombre del Hotel
            Text(
              widget.hotel.nombre,
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
                  return const Icon(
                    Icons.star,
                    size: 20,
                    color: Color(0xFFE59819),
                  );
                }),
                const SizedBox(width: 8),
                const Text(
                  '4.8 · 36 reseñas verificadas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fila de 4 tarjetas de métricas rápidas
            _buildQuickInfoGrid(),
            const SizedBox(height: 28),

            // Sección: Descripción
            const Text(
              'Sobre el hospedaje',
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
                fontSize: 14.5,
                height: 1.6,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 28),

            // Sección: Amenidades y Servicios
            _buildAmenidadesSection(),
            const SizedBox(height: 28),

            // Sección: Contacto de Recepción
            _buildContactoCard(),
            const SizedBox(height: 28),

            // Sección: Ubicación & Mapa
            _buildUbicacionSection(),
            const SizedBox(height: 28),

            // Sección: Normas de la Estancia
            _buildNormasSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    return Row(
      children: [
        // 1. Tipo
        Expanded(
          child: _buildInfoItem(
            icon: Icons.apartment_outlined,
            title: 'TIPO',
            value: _tipoHospedaje,
          ),
        ),
        const SizedBox(width: 8),

        // 2. Precios
        Expanded(
          child: _buildInfoItem(
            icon: Icons.payments_outlined,
            title: 'PRECIOS',
            value: _precioTexto,
            valueColor: const Color(0xFF26674B),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Check-in
        Expanded(
          child: _buildInfoItem(
            icon: Icons.schedule_outlined,
            title: 'CHECK-IN',
            value: '13:00 / 11:00',
          ),
        ),
        const SizedBox(width: 8),

        // 4. Ubicación
        Expanded(
          child: _buildInfoItem(
            icon: Icons.place_outlined,
            title: 'ZONA',
            value: 'Comarapa',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5A3F)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenidadesSection() {
    final amenidades = _amenidadesList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios y comodidades',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143525),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: amenidades.map((amenidad) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForAmenity(amenidad),
                    size: 16,
                    color: const Color(0xFF26674B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amenidad,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContactoCard() {
    final contacto = widget.hotel.contactoReservas?.isNotEmpty == true
        ? widget.hotel.contactoReservas!
        : '+591 3 936 1000';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2ECE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.room_service_outlined,
              color: Color(0xFF1B5A3F),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECEPCIÓN Y RESERVAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.hotel.nombre,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contacto,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_forwarded, color: Color(0xFF26674B)),
            onPressed: () => _showBookingDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
              ),
            ),
            TextButton.icon(
              onPressed: () => _openFullMap(context),
              icon: const Icon(Icons.fullscreen, size: 18, color: Color(0xFF1B5A3F)),
              label: const Text(
                'Ampliar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5A3F),
                ),
              ),
            ),
          ],
        ),
        if (widget.hotel.direccionReferencia?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.hotel.direccionReferencia!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _locationPoint,
                  initialZoom: 14.5,
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
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF26674B),
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openFullMap(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNormasSection() {
    const normas = [
      'Check-in a partir de las 13:00 / Check-out hasta las 11:00.',
      'Horario de silencio y descanso a partir de las 22:30.',
      'Prohibido fumar en las habitaciones.',
      'Consultar previamente con recepción sobre mascotas (pet-friendly bajo solicitud).',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Políticas y normas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143525),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        ...normas.map((norma) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2ECE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Color(0xFF1B5A3F),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    norma,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF4B5563),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Precios
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PRECIO POR NOCHE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _precioTexto,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143525),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ noche',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Botón principal
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showBookingDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26674B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Reservar / Contactar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
