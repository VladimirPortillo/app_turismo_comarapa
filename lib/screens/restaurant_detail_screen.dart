import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../models/restaurante.dart';
import '../repositories/gastronomia_repository.dart';
import '../widgets/full_map_sheet.dart';
import '../widgets/fullscreen_image_gallery.dart';
import '../widgets/resenas_section.dart';
import 'gastronomy_detail_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurante restaurante;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurante,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  double _promedioResenas = 0;
  int _totalResenas = 0;

  List<GastronomiaItem> _platosVinculados = <GastronomiaItem>[];
  bool _cargandoPlatos = false;

  // Coordenadas por defecto (Comarapa) si el restaurante no tiene ubicación asignada
  static const double _defaultLat = -18.0447;
  static const double _defaultLng = -64.5301;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final restauranteId = widget.restaurante.id;
    if (restauranteId != null) {
      _cargarPlatosVinculados(restauranteId);
    }
  }

  Future<void> _cargarPlatosVinculados(String restauranteId) async {
    setState(() => _cargandoPlatos = true);
    try {
      final repo = context.read<GastronomiaRepository>();
      final platos = await repo.fetchByRestaurante(restauranteId);
      if (!mounted) return;
      setState(() {
        _platosVinculados = platos;
        _cargandoPlatos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoPlatos = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  LatLng get _locationPoint {
    final lat = widget.restaurante.latitud;
    final lng = widget.restaurante.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return const LatLng(_defaultLat, _defaultLng);
  }

  String get _categoriaLabel {
    final cat = widget.restaurante.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'RESTAURANTE';
  }

  String get _horarioTexto {
    final h = widget.restaurante.horarioAtencion;
    if (h != null && h.trim().isNotEmpty) {
      return h.trim();
    }
    return '';
  }

  String get _preciosTexto {
    final p = widget.restaurante.precioReferencial;
    if (p != null && p > 0) {
      return 'Bs ${p.toInt()} ref.';
    }
    return '';
  }

  String get _contactoTexto {
    final c = widget.restaurante.contacto;
    if (c != null && c.trim().isNotEmpty) {
      return c.trim();
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
              titulo: widget.restaurante.nombre,
              subtitulo: widget.restaurante.direccionReferencia?.isNotEmpty == true
                  ? widget.restaurante.direccionReferencia
                  : 'Comarapa, Santa Cruz',
              destino: _locationPoint,
            );
          },
        );
      },
    );
  }

  void _showContactModal(BuildContext context) {
    if (_contactoTexto.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.restaurante.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C3D28),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Información y reservas gastronómicas:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF7F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFF1B5A3F)),
                ),
                title: const Text('Teléfono de contacto'),
                subtitle: Text(_contactoTexto),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Color(0xFF1B5A3F)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _contactoTexto));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Número telefónico copiado al portapapeles'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              if (_horarioTexto.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9EFE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time, color: Color(0xFFC68B59)),
                  ),
                  title: const Text('Horario habitual'),
                  subtitle: Text(_horarioTexto),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _contactoTexto));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacto "$_contactoTexto" copiado al portapapeles'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar contacto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5A3F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.restaurante.imagenes;
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

                // Tarjeta de información con bordes redondeados superpuesta
                _buildContentCard(),
              ],
            ),
          ),

          // Barra inferior fija
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
    final imagenes = widget.restaurante.imagenes;

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
            Color(0xFF7C2D12),
            Color(0xFF9A3412),
            Color(0xFFB45309),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: RestaurantHeroPainter(),
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
    final tieneDescripcion = widget.restaurante.descripcion.trim().isNotEmpty;
    final tieneUbicacion = widget.restaurante.latitud != null &&
        widget.restaurante.longitud != null &&
        widget.restaurante.latitud != 0 &&
        widget.restaurante.longitud != 0;
    final tienePlatos = _cargandoPlatos || _platosVinculados.isNotEmpty;

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
                color: const Color(0xFFF9EFE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categoriaLabel,
                style: const TextStyle(
                  color: Color(0xFFC68B59),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del Restaurante
            Text(
              widget.restaurante.nombre,
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
                      : '${_promedioResenas.toStringAsFixed(1)} · $_totalResenas ${_totalResenas == 1 ? "opinión" : "opiniones"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjetas de información rápida (solo datos reales de la BD)
            _buildQuickInfoRow(),
            const SizedBox(height: 28),

            // Sección: Descripción (solo si existe en la BD)
            if (tieneDescripcion) ...[
              const Text(
                'Sobre el restaurante',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.restaurante.descripcion.trim(),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4B5563),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Sección: Platos y especialidades de la casa
            if (tienePlatos) ...[
              _buildEspecialidadesSection(),
              const SizedBox(height: 28),
            ],

            // Sección: Ubicación y mapa (solo si tiene coordenadas en la BD)
            if (tieneUbicacion) ...[
              const Text(
                'Ubicación y mapa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 12),
              _buildMiniMap(),
              if (widget.restaurante.direccionReferencia != null &&
                  widget.restaurante.direccionReferencia!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, size: 18, color: Color(0xFFC68B59)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.restaurante.direccionReferencia!.trim(),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF4B5563),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
            ],

            // Sección: Reseñas
            if (widget.restaurante.id != null)
              ResenasSection(
                entidad: 'restaurante',
                entidadId: widget.restaurante.id!,
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

  Widget _buildQuickInfoRow() {
    final items = <Widget>[];

    // 1. Horario de atención
    if (_horarioTexto.isNotEmpty) {
      items.add(_buildInfoCard(
        icon: Icons.access_time_outlined,
        title: 'Horario',
        value: _horarioTexto,
      ));
    }

    // 2. Precios referenciales
    if (_preciosTexto.isNotEmpty) {
      items.add(_buildInfoCard(
        icon: Icons.payments_outlined,
        title: 'Precios',
        value: _preciosTexto,
        valueColor: const Color(0xFF1B5A3F),
      ));
    }

    // 3. Contacto telefónico
    if (_contactoTexto.isNotEmpty) {
      items.add(_buildInfoCard(
        icon: Icons.phone_in_talk_outlined,
        title: 'Contacto',
        value: _contactoTexto,
      ));
    }

    // 4. Ubicación de referencia (si no hay 3 tarjetas aún)
    if (items.length < 3 &&
        widget.restaurante.direccionReferencia != null &&
        widget.restaurante.direccionReferencia!.trim().isNotEmpty) {
      items.add(_buildInfoCard(
        icon: Icons.place_outlined,
        title: 'Referencia',
        value: widget.restaurante.direccionReferencia!.trim(),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF1B5A3F),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
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

  Widget _buildEspecialidadesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platos típicos que ofrece',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143525),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 14),
        if (_cargandoPlatos)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_platosVinculados.isEmpty)
          Text(
            'Aún no se registraron platos típicos para este restaurante.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          )
        else
          ..._platosVinculados.map((plato) {
            final precio = plato.precioReferencial;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GastronomyDetailScreen(item: plato),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9EFE5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFFC68B59),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  plato.nombre,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (precio != null && precio > 0)
                                Text(
                                  'Bs ${precio.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5A3F),
                                  ),
                                ),
                            ],
                          ),
                          if (plato.descripcion.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              plato.descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }



  Widget _buildMiniMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
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
                initialZoom: 15.0,
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
                        Icons.restaurant,
                        size: 34,
                        color: Color(0xFFC68B59),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Capa táctil para abrir el mapa expandido
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFullMap(context),
                ),
              ),
            ),

            // Botón indicador de ampliar mapa
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, size: 16, color: Color(0xFF1B5A3F)),
                    SizedBox(width: 4),
                    Text(
                      'Ampliar mapa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5A3F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final tienePrecio = _preciosTexto.isNotEmpty;
    final tieneContacto = _contactoTexto.isNotEmpty;
    final tieneUbicacion = widget.restaurante.latitud != null &&
        widget.restaurante.longitud != null &&
        widget.restaurante.latitud != 0 &&
        widget.restaurante.longitud != 0;

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
            // Resumen de precios (si existen en la BD)
            if (tienePrecio) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PRECIO APROX.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _preciosTexto,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143525),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],

            // Botón de contacto / ver mapa
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (tieneContacto) {
                      _showContactModal(context);
                    } else if (tieneUbicacion) {
                      _openFullMap(context);
                    }
                  },
                  icon: Icon(
                    tieneContacto ? Icons.phone_outlined : Icons.map_outlined,
                    size: 18,
                  ),
                  label: Text(
                    tieneContacto
                        ? 'Contactar / Reservar'
                        : (tieneUbicacion ? 'Ver en el mapa' : 'Ubicación no disponible'),
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

/// Custom painter que dibuja una ilustración vectorial para restaurantes
class RestaurantHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Luces cálidas de ambientación en el fondo
    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.4), radius: 100));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 100, lightPaint);

    // Silueta de mesa de mantel
    final tablePaint = Paint()
      ..color = const Color(0xFF451A03).withValues(alpha: 0.65);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.65, size.width * 0.7, size.height * 0.35),
        const Radius.circular(8),
      ),
      tablePaint,
    );

    // Plato elegante y campana de cocina
    final cx = size.width * 0.5;
    final cy = size.height * 0.55;

    final clochePaint = Paint()..color = const Color(0xFFFDE68A);

    // Plato
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 12), width: 72, height: 16),
      clochePaint,
    );

    // Domo de la campana
    final domePath = Path()
      ..moveTo(cx - 30, cy + 12)
      ..quadraticBezierTo(cx, cy - 30, cx + 30, cy + 12)
      ..close();
    canvas.drawPath(domePath, clochePaint);

    // Agarrador de la campana
    canvas.drawCircle(Offset(cx, cy - 30), 5, clochePaint);

    // Cubiertos a los lados
    final cutleryPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Tenedor izquierda
    canvas.drawLine(Offset(cx - 52, cy + 18), Offset(cx - 52, cy - 6), cutleryPaint);
    // Cuchillo derecha
    canvas.drawLine(Offset(cx + 52, cy + 18), Offset(cx + 52, cy - 6), cutleryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
