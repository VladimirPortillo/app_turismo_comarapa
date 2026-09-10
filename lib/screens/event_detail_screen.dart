import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/evento.dart';
import '../widgets/full_map_sheet.dart';
import '../widgets/fullscreen_image_gallery.dart';
import '../widgets/resenas_section.dart';

class EventDetailScreen extends StatefulWidget {
  final Evento evento;

  const EventDetailScreen({
    super.key,
    required this.evento,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  double _promedioResenas = 0;
  int _totalResenas = 0;

  // Coordenadas por defecto (Comarapa) si el evento no tiene ubicación asignada
  static const double _defaultLat = -18.0447;
  static const double _defaultLng = -64.5301;

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
    final lat = widget.evento.latitud;
    final lng = widget.evento.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  String get _categoriaLabel {
    final cat = widget.evento.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'EVENTO';
  }

  String get _fechasRangoTexto {
    final inicio = widget.evento.fechaInicio;
    final fin = widget.evento.fechaFin;
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final mesStr = (inicio.month >= 1 && inicio.month <= 12) ? meses[inicio.month - 1] : '';

    if (fin != null && (fin.day != inicio.day || fin.month != inicio.month || fin.year != inicio.year)) {
      if (inicio.month == fin.month && inicio.year == fin.year) {
        return 'Del ${inicio.day} al ${fin.day} de $mesStr';
      } else {
        final mesFinStr = (fin.month >= 1 && fin.month <= 12) ? meses[fin.month - 1] : '';
        return '${inicio.day} de $mesStr al ${fin.day} de $mesFinStr';
      }
    }
    return '${inicio.day} de $mesStr';
  }

  String get _periodicidadTexto {
    final per = widget.evento.periodicidad?.trim();
    if (per != null && per.isNotEmpty) {
      return per[0].toUpperCase() + per.substring(1).toLowerCase();
    }
    return '';
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
            return FullMapSheet(
              titulo: widget.evento.nombre,
              subtitulo: 'Lugar de celebración · Comarapa',
              destino: _locationPoint,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.evento.imagenes;
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
    final imagenes = widget.evento.imagenes;

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
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => FullscreenImageGallery(
                          imagenes: imagenes,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIllustration(),
                  ),
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
          // Barra superior de navegación con botón volver
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Botón Volver
                  _buildCircleButton(
                    icon: Icons.chevron_left,
                    iconSize: 26,
                    onTap: () => Navigator.of(context).pop(),
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
            Color(0xFF8C4717),
            Color(0xFFB45309),
            Color(0xFF1B5A3F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.evento.nombre,
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
    final tieneDescripcion = widget.evento.descripcion.trim().isNotEmpty;
    final tieneUbicacion = widget.evento.latitud != null &&
        widget.evento.longitud != null &&
        widget.evento.latitud != 0 &&
        widget.evento.longitud != 0;

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

            // Nombre del Evento
            Text(
              widget.evento.nombre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Rango de fechas destacado
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Color(0xFF26674B)),
                const SizedBox(width: 8),
                Text(
                  _fechasRangoTexto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26674B),
                  ),
                ),
                if (_periodicidadTexto.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _periodicidadTexto,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Puntuación y Reseñas
            Row(
              children: [
                ...List.generate(5, (i) {
                  final activo = i < _promedioResenas.round();
                  return Icon(
                    activo ? Icons.star : Icons.star_border,
                    size: 20,
                    color: const Color(0xFFE59819),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _totalResenas == 0
                      ? 'Sin reseñas todavía'
                      : '${_promedioResenas.toStringAsFixed(1)} · $_totalResenas ${_totalResenas == 1 ? "reseña" : "reseñas"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fila de tarjetas de métricas rápidas (solo datos reales de la BD)
            _buildQuickInfoGrid(),
            const SizedBox(height: 28),

            // Sección: Descripción (solo si existe en la BD)
            if (tieneDescripcion) ...[
              const Text(
                'Sobre el evento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.evento.descripcion.trim(),
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Sección: Ubicación & Mapa (solo si tiene coordenadas en la BD)
            if (tieneUbicacion) ...[
              _buildUbicacionSection(),
              const SizedBox(height: 28),
            ],

            // Sección: Reseñas
            if (widget.evento.id != null)
              ResenasSection(
                entidad: 'evento',
                entidadId: widget.evento.id!,
                onResumenActualizado: (promedio, total) {
                  setState(() {
                    _promedioResenas = promedio;
                    _totalResenas = total;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    final items = <Widget>[];

    // 1. Fecha de inicio
    items.add(_buildInfoItem(
      icon: Icons.event_outlined,
      title: 'INICIO',
      value: '${widget.evento.diaFormateado} ${widget.evento.mesAbreviado}',
    ));

    // 2. Duración (si fechaFin existe)
    if (widget.evento.fechaFin != null) {
      final diff = widget.evento.fechaFin!.difference(widget.evento.fechaInicio).inDays + 1;
      final duracionStr = diff > 1 ? '$diff días' : '1 día';
      items.add(_buildInfoItem(
        icon: Icons.date_range_outlined,
        title: 'DURACIÓN',
        value: duracionStr,
      ));
    }

    // 3. Periodicidad
    if (_periodicidadTexto.isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.repeat_outlined,
        title: 'FRECUENCIA',
        value: _periodicidadTexto,
      ));
    }

    // 4. Tipo / Categoría
    if (widget.evento.categoriaNombre != null && widget.evento.categoriaNombre!.trim().isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.category_outlined,
        title: 'TIPO',
        value: widget.evento.categoriaNombre!.trim(),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: items[i]),
        ],
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

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lugar del evento',
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
        const SizedBox(height: 10),
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

  Widget _buildBottomBar(BuildContext context) {
    final tieneUbicacion = widget.evento.latitud != null &&
        widget.evento.longitud != null &&
        widget.evento.latitud != 0 &&
        widget.evento.longitud != 0;

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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Fecha del evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FECHA DEL EVENTO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fechasRangoTexto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143525),
                    ),
                  ),
                ],
              ),
            ),

            // Botón de acción: Ver en el mapa si tiene ubicación
            if (tieneUbicacion) ...[
              const SizedBox(width: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _openFullMap(context),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Ver en el mapa',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26674B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
