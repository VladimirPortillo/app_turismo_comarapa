import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/actividad.dart';
import '../models/turismo_tipo.dart';
import '../widgets/full_map_sheet.dart';
import '../widgets/fullscreen_image_gallery.dart';
import '../widgets/resenas_section.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Actividad actividad;

  const ActivityDetailScreen({
    super.key,
    required this.actividad,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  double _promedioResenas = 0;
  int _totalResenas = 0;

  // Coordenadas por defecto (Comarapa) si la actividad no tiene ubicación asignada
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
    final lat = widget.actividad.latitud;
    final lng = widget.actividad.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  String get _categoriaLabel {
    final cat = widget.actividad.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'ACTIVIDAD';
  }

  String get _duracionTexto {
    final minutos = widget.actividad.duracionMin;
    if (minutos == null || minutos <= 0) return '';
    if (minutos < 60) return '$minutos min';
    final horas = minutos / 60;
    final horasTexto =
        horas == horas.roundToDouble() ? horas.toInt().toString() : horas.toStringAsFixed(1);
    return '$horasTexto ${horas == 1 ? "hora" : "horas"}';
  }

  String get _dificultadTexto {
    final dif = widget.actividad.dificultad;
    if (dif.isEmpty) return 'Fácil';
    return dificultadLabel(dif);
  }

  Color get _dificultadColor {
    final dif = widget.actividad.dificultad.toLowerCase();
    if (dif.contains('dificil') || dif.contains('alta') || dif.contains('exigente')) {
      return const Color(0xFFDC2626);
    }
    if (dif.contains('moderada') || dif.contains('media')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF16A34A);
  }

  String get _precioTexto {
    final p = widget.actividad.precioReferencial;
    if (p != null && p > 0) {
      return 'Bs ${p.toInt()}';
    }
    if (p == 0) return 'Gratis';
    return '';
  }


  void _showBookingDialog(BuildContext context) {
    final contacto = widget.actividad.operadorContacto?.trim();
    if (contacto == null || contacto.isEmpty) return;

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
                'Información de contacto registrada para "${widget.actividad.nombre}":',
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
                      child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OPERADOR / GUÍA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contacto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0C3D28),
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
                    Clipboard.setData(ClipboardData(text: contacto));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacto "$contacto" copiado al portapapeles'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text(
                    'Copiar Contacto',
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
            return FullMapSheet(
              titulo: widget.actividad.nombre,
              subtitulo: 'Punto de encuentro y partida · Comarapa',
              destino: _locationPoint,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.actividad.imagenes;
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
    final imagenes = widget.actividad.imagenes;

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
                Icons.hiking,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.actividad.nombre,
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
    final tieneDescripcion = widget.actividad.descripcion.trim().isNotEmpty;
    final tieneOperador = widget.actividad.operadorContacto?.trim().isNotEmpty == true;
    final tieneUbicacion = widget.actividad.latitud != null &&
        widget.actividad.longitud != null &&
        widget.actividad.latitud != 0 &&
        widget.actividad.longitud != 0;

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

            // Nombre de la Actividad
            Text(
              widget.actividad.nombre,
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

            // Fila de tarjetas de información rápida (solo campos con datos reales en BD)
            _buildQuickInfoGrid(),
            const SizedBox(height: 28),

            // Sección: Descripción (solo si está guardada en la BD)
            if (tieneDescripcion) ...[
              const Text(
                'Descripción de la actividad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.actividad.descripcion.trim(),
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Sección: Operador / Guía de Contacto (solo si está registrado en la BD)
            if (tieneOperador) ...[
              _buildOperadorCard(),
              const SizedBox(height: 28),
            ],

            // Sección: Punto de Partida / Mapa (solo si tiene coordenadas en la BD)
            if (tieneUbicacion) ...[
              _buildUbicacionSection(),
              const SizedBox(height: 28),
            ],

            // Sección: Reseñas (guardadas en la BD)
            if (widget.actividad.id != null)
              ResenasSection(
                entidad: 'actividad',
                entidadId: widget.actividad.id!,
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

    // 1. Duración (solo si existe en la BD)
    if (_duracionTexto.isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.access_time_outlined,
        title: 'DURACIÓN',
        value: _duracionTexto,
      ));
    }

    // 2. Dificultad (siempre existe en la BD)
    items.add(_buildInfoItem(
      icon: Icons.fitness_center_outlined,
      title: 'DIFICULTAD',
      value: _dificultadTexto,
      valueColor: _dificultadColor,
    ));

    // 3. Precio referencial (solo si está registrado en la BD)
    if (_precioTexto.isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.payments_outlined,
        title: 'PRECIO',
        value: _precioTexto,
      ));
    }

    // 4. Capacidad máxima (solo si está registrada en la BD)
    if (widget.actividad.capacidadMaxima != null && widget.actividad.capacidadMaxima! > 0) {
      items.add(_buildInfoItem(
        icon: Icons.people_outline,
        title: 'CAPACIDAD',
        value: 'Máx. ${widget.actividad.capacidadMaxima} pers.',
      ));
    }

    // 5. Temporada (columna real en la BD)
    if (widget.actividad.temporada != null && widget.actividad.temporada!.trim().isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.calendar_month_outlined,
        title: 'TEMPORADA',
        value: widget.actividad.temporada!.trim(),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    if (items.length <= 4) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: items[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 8),
            Expanded(child: items[1]),
            const SizedBox(width: 8),
            Expanded(child: items[2]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 3; i < items.length; i++) ...[
              if (i > 3) const SizedBox(width: 8),
              Expanded(child: items[i]),
            ],
          ],
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
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperadorCard() {
    final operador = widget.actividad.operadorContacto?.trim();
    if (operador == null || operador.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icons.hiking,
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
                  'OPERADOR / GUÍA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  operador,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
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
              'Punto de partida',
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
    final tienePrecio = widget.actividad.precioReferencial != null &&
        widget.actividad.precioReferencial! > 0;
    final tieneOperador = widget.actividad.operadorContacto?.trim().isNotEmpty == true;

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
            // Precio referencial si existe en la BD
            if (tienePrecio) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PRECIO REFERENCIAL',
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF143525),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ persona',
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
            ],

            // Botón principal: Contactar (si hay operador) o Ver en el mapa
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (tieneOperador) {
                      _showBookingDialog(context);
                    } else {
                      _openFullMap(context);
                    }
                  },
                  icon: Icon(
                    tieneOperador ? Icons.contact_phone_outlined : Icons.map_outlined,
                    size: 20,
                  ),
                  label: Text(
                    tieneOperador ? 'Contactar Guía' : 'Ver en el mapa',
                    style: const TextStyle(
                      fontSize: 15,
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
            ),
          ],
        ),
      ),
    );
  }
}
