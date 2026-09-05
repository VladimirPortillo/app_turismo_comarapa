import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/evento.dart';

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
  bool _isFavorite = false;

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
    return 'FERIA TRADICIONAL';
  }

  String get _fechasRangoTexto {
    final inicio = widget.evento.fechaInicio;
    final fin = widget.evento.fechaFin;
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final mesStr = (inicio.month >= 1 && inicio.month <= 12) ? meses[inicio.month - 1] : '';

    if (fin != null && (fin.day != inicio.day || fin.month != inicio.month)) {
      if (inicio.month == fin.month) {
        return 'Del ${inicio.day} al ${fin.day} de $mesStr';
      } else {
        final mesFinStr = (fin.month >= 1 && fin.month <= 12) ? meses[fin.month - 1] : '';
        return '${inicio.day} de $mesStr al ${fin.day} de $mesFinStr';
      }
    }
    return '${inicio.day} de $mesStr';
  }

  String get _periodicidadTexto {
    final per = widget.evento.periodicidad?.toLowerCase() ?? 'anual';
    return (per == 'único' || per == 'unico') ? 'Único' : 'Anual';
  }

  String get _descripcionTexto {
    final desc = widget.evento.descripcion;
    if (desc.trim().isNotEmpty) {
      return desc;
    }
    return 'Una de las festividades más representativas de Comarapa. Reúne a productores, '
        'comunidades campesinas, artesanos y visitantes en un ambiente de alegría, música '
        'folclórica tradicional, danzas típicas y exposición de los mejores frutos del valle.';
  }

  List<String> get _programaDestacado {
    final name = widget.evento.nombre.toLowerCase();
    if (name.contains('durazno')) {
      return [
        'Inauguración oficial y bendición de los primeros frutos de la cosecha.',
        'Exposición y juzgamiento de las mejores variedades de durazno comarapeño.',
        'Elección y coronación de la Reina Nacional del Durazno.',
        'Feria gastronómica: repostería, licores, mermeladas y platos típicos.',
        'Gran serenata folclórica con artistas nacionales y comarapeños.',
      ];
    } else if (name.contains('candelaria') || name.contains('patronal')) {
      return [
        'Misa solemne de fiesta en el templo parroquial de Comarapa.',
        'Procesión con la venerada imagen por las calles históricas del municipio.',
        'Entrada folclórica con fraternidades autóctonas y danzas tradicionales.',
        'Fuegos artificiales, verbena popular y juegos tradicionales vallunos.',
      ];
    } else if (name.contains('maíz') || name.contains('maiz')) {
      return [
        'Demostración de molienda tradicional y derivados del maíz.',
        'Degustación de chicha dulce, humintas y api con pastel.',
        'Concurso al choclo y mazorca de mayor tamaño y calidad.',
        'Festival de coplas y música tradicional de los valles.',
      ];
    }
    return [
      'Acto inaugural y bienvenida a delegaciones y turistas.',
      'Exposición artesanal y de productos típicos del municipio.',
      'Presentaciones culturales, danzas y música folclórica en vivo.',
      'Clausura y premiación a los expositores destacados.',
    ];
  }

  void _onShare() {
    Clipboard.setData(ClipboardData(
      text: '${widget.evento.nombre} (${_fechasRangoTexto}) - Eventos Comarapa Turismo',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace de "${widget.evento.nombre}" copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCalendarModal(BuildContext context) {
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
                'Detalles de Asistencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C3D28),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Información importante para asistir a "${widget.evento.nombre}":',
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
                      child: const Icon(Icons.event_available, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fechasRangoTexto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Color(0xFF0C3D28),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Entrada libre y gratuita para todo público',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF16A34A),
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
                      SnackBar(
                        content: Text('Recordatorio guardado para "${widget.evento.nombre}". ¡Te esperamos en Comarapa!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.alarm_on, size: 18),
                  label: const Text(
                    'Guardar recordatorio de evento',
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
                                widget.evento.nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C3D28),
                                  fontFamily: 'serif',
                                ),
                              ),
                              const Text(
                                'Lugar de celebración · Comarapa',
                                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
                                    ? 'Añadido a tus eventos guardados'
                                    : 'Eliminado de tus eventos guardados',
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
            ),
            const SizedBox(height: 24),

            // Fila de 4 tarjetas de métricas rápidas
            _buildQuickInfoGrid(),
            const SizedBox(height: 28),

            // Sección: Descripción
            const Text(
              'Sobre la festividad',
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

            // Sección: Programa Destacado
            _buildProgramaSection(),
            const SizedBox(height: 28),

            // Sección: Organización y Contacto
            _buildComiteCard(),
            const SizedBox(height: 28),

            // Sección: Ubicación & Mapa
            _buildUbicacionSection(),
            const SizedBox(height: 28),

            // Sección: Recomendaciones para el Visitante
            _buildRecomendacionesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    return Row(
      children: [
        // 1. Fecha corta
        Expanded(
          child: _buildInfoItem(
            icon: Icons.event_outlined,
            title: 'FECHA',
            value: '${widget.evento.diaFormateado} ${widget.evento.mesAbreviado}',
          ),
        ),
        const SizedBox(width: 8),

        // 2. Frecuencia
        Expanded(
          child: _buildInfoItem(
            icon: Icons.repeat_outlined,
            title: 'FRECUENCIA',
            value: _periodicidadTexto,
          ),
        ),
        const SizedBox(width: 8),

        // 3. Lugar
        Expanded(
          child: _buildInfoItem(
            icon: Icons.place_outlined,
            title: 'LUGAR',
            value: 'Comarapa',
          ),
        ),
        const SizedBox(width: 8),

        // 4. Acceso
        Expanded(
          child: _buildInfoItem(
            icon: Icons.confirmation_number_outlined,
            title: 'ACCESO',
            value: 'Gratuito',
            valueColor: const Color(0xFF16A34A),
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

  Widget _buildProgramaSection() {
    final actividades = _programaDestacado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programa y actividades destacadas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143525),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        ...actividades.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final act = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2ECE7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$idx',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5A3F),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    act,
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

  Widget _buildComiteCard() {
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
              Icons.account_balance_outlined,
              color: Color(0xFF1B5A3F),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORGANIZACIÓN Y COORDINACIÓN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gobierno Municipal de Comarapa',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dirección de Turismo y Cultura',
                  style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF26674B)),
            onPressed: () => _showCalendarModal(context),
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

  Widget _buildRecomendacionesSection() {
    const tips = [
      'Llegar con anticipación a las actividades principales para asegurar buena ubicación.',
      'Llevar dinero en efectivo para adquirir artesanías, frutas y platillos típicos.',
      'Portar sombrero o gorra durante las actividades diurnas y abrigo para las veladas nocturnas.',
      'Seguir las indicaciones del personal de orden y cuidar los espacios públicos.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones para el visitante',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143525),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        ...tips.map((tip) {
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
                    tip,
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
          // Acceso
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ACCESO AL EVENTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Entrada Libre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Botón principal
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showCalendarModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26674B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Recordatorio / Asistir',
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
