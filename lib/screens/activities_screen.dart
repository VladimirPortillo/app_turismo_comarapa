import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/actividad.dart';
import '../models/turismo_tipo.dart';
import '../repositories/actividad_repository.dart';
import 'activity_detail_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ActivitiesScreen({super.key, required this.onBack});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Actividad> _actividades = <Actividad>[];

  // Datos demo curados para Comarapa en caso de offline o tabla vacía
  static final List<Actividad> _demoActividades = [
    Actividad(
      id: 'demo-act-1',
      nombre: 'Trekking Cañón de la Pajcha',
      categoriaNombre: 'Trekking & Senderismo',
      descripcion: 'Recorrido a pie atravesando formaciones rocosas, caídas de agua cristalina y senderos rodeados de vegetación virgen. Una aventura imperdible para amantes de la naturaleza.',
      dificultad: 'moderada',
      duracionMin: 180,
      precioReferencial: 50,
      operadorContacto: 'Asoc. de Guías Ecológicos Comarapa',
      capacidadMaxima: 12,
      temporada: 'Todo el año',
      latitud: -18.0250,
      longitud: -64.5120,
      activo: true,
    ),
    Actividad(
      id: 'demo-act-2',
      nombre: 'Cabalgata por los Valles',
      categoriaNombre: 'Cabalgata',
      descripcion: 'Paseo guiado a caballo por los huertos de durazno, maizales y miradores naturales con vista panorámica a la cordillera y los valles comarapeños.',
      dificultad: 'facil',
      duracionMin: 120,
      precioReferencial: 80,
      operadorContacto: 'Hacienda El Paraíso Tours',
      capacidadMaxima: 8,
      temporada: 'Marzo - Noviembre',
      latitud: -18.0480,
      longitud: -64.5380,
      activo: true,
    ),
    Actividad(
      id: 'demo-act-3',
      nombre: 'Avistamiento de Aves en Amboró',
      categoriaNombre: 'Ecoturismo',
      descripcion: 'Excursión matutina en el bosque nublado del Área Protegida Amboró, hogar de la paraba frente roja, tucanes y cientos de aves endémicas de Bolivia.',
      dificultad: 'facil',
      duracionMin: 240,
      precioReferencial: 70,
      operadorContacto: 'Comarapa Birdwatching Club',
      capacidadMaxima: 10,
      temporada: 'Todo el año',
      latitud: -17.9100,
      longitud: -64.5300,
      activo: true,
    ),
    Actividad(
      id: 'demo-act-4',
      nombre: 'Ruta Cactáceas en Bicicleta',
      categoriaNombre: 'Aventura',
      descripcion: 'Circuito cicloturístico por el valle seco interandino contemplando especies gigantes de cactus, senderos de tierra y descensos emocionantes.',
      dificultad: 'moderada',
      duracionMin: 150,
      precioReferencial: 45,
      operadorContacto: 'Comarapa Mountain Bike',
      capacidadMaxima: 15,
      temporada: 'Todo el año',
      latitud: -18.0620,
      longitud: -64.5190,
      activo: true,
    ),
    Actividad(
      id: 'demo-act-5',
      nombre: 'Circuito de Moliendas y Tradición',
      categoriaNombre: 'Cultural',
      descripcion: 'Visita guiada a fincas tradicionales de elaboración de chancaca, derivados del durazno y licores artesanales, con degustación incluida.',
      dificultad: 'facil',
      duracionMin: 90,
      precioReferencial: 30,
      operadorContacto: 'Comunidad Artesanal del Valle',
      capacidadMaxima: 20,
      temporada: 'Enero - Mayo',
      latitud: -18.0370,
      longitud: -64.5260,
      activo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<ActividadRepository>();
      final list = await repo.fetchActivos();
      if (!mounted) return;
      setState(() {
        _actividades = list.isNotEmpty ? list : _demoActividades;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // En caso de error o modo offline, usar las actividades demo enriquecidas
      setState(() {
        _actividades = _demoActividades;
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final a in _actividades)
        if (a.categoriaNombre != null && a.categoriaNombre!.trim().isNotEmpty)
          a.categoriaNombre!.trim(),
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<Actividad> get _filteredActividades {
    final query = _searchQuery.toLowerCase();
    return _actividades.where((act) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || act.categoriaNombre == _selectedCategoria;
      final matchesSearch = act.nombre.toLowerCase().contains(query) ||
          (act.categoriaNombre ?? '').toLowerCase().contains(query) ||
          act.descripcion.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String nombre) {
    final name = nombre.toLowerCase();
    if (name.contains('trekking') || name.contains('senderismo') || name.contains('cañón')) {
      return TrailHikerPainter();
    } else if (name.contains('caballo') || name.contains('cabalgata')) {
      return HorseValleyPainter();
    } else if (name.contains('ave') || name.contains('amboró') || name.contains('eco')) {
      return ForestCanopyPainter();
    } else if (name.contains('bici') || name.contains('aventura') || name.contains('cactus')) {
      return BikeAdventurePainter();
    } else {
      return CulturalTraditionPainter();
    }
  }

  String _duracionLabel(Actividad act) {
    final minutos = act.duracionMin;
    if (minutos == null || minutos <= 0) return '2 horas';
    if (minutos < 60) return '$minutos min';
    final horas = minutos / 60;
    final horasTexto =
        horas == horas.roundToDouble() ? horas.toInt().toString() : horas.toStringAsFixed(1);
    return '$horasTexto ${horas == 1 ? "hora" : "horas"}';
  }

  Color _dificultadDotColor(String dif) {
    final d = dif.toLowerCase();
    if (d.contains('dificil') || d.contains('alta') || d.contains('exigente')) {
      return const Color(0xFFDC2626);
    }
    if (d.contains('moderada') || d.contains('media')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSearchBar(),
        const SizedBox(height: 20),
        _buildCategoriesSelector(),
        const SizedBox(height: 16),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Actividades turísticas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C3D28),
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar actividades, trekking, aventura...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSelector() {
    final categorias = _categorias;
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final category = categorias[index];
          final isSelected = _selectedCategoria == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategoria = category);
                }
              },
              selectedColor: const Color(0xFF1B5A3F),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1B5A3F) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredActividades;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildActivityCard(filtered[index]),
            ),
    );
  }

  Widget _buildActivityCard(Actividad actividad) {
    final precio = actividad.precioReferencial;
    final precioTexto = precio != null && precio > 0 ? 'Bs ${precio.toInt()}' : 'Gratis';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(actividad: actividad),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura ilustrada o foto
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: actividad.imagenes.isNotEmpty
                    ? Image.network(
                        actividad.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _painterFor(actividad.nombre),
                        ),
                      )
                    : CustomPaint(painter: _painterFor(actividad.nombre)),
              ),
              const SizedBox(width: 16),

              // Contenido central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2ECE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        actividad.categoriaNombre ?? 'Actividad',
                        style: const TextStyle(
                          color: Color(0xFF1B5A3F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Nombre de la actividad
                    Text(
                      actividad.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fila de metadatos (duración, dificultad y precio)
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _duracionLabel(actividad),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _dificultadDotColor(actividad.dificultad),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dificultadLabel(actividad.dificultad),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: _dificultadDotColor(actividad.dificultad),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            precioTexto,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.explore_off_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No se encontraron actividades',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prueba ajustando el término de búsqueda o categoría',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pintores artísticos temáticos para las miniaturas de actividades
// ---------------------------------------------------------------------------

class TrailHikerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo cielo / montaña
    final bgPaint = Paint()..color = const Color(0xFFE2F0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final mountainPaint = Paint()..color = const Color(0xFF1B5A3F);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, mountainPaint);

    // Sendero
    final trailPaint = Paint()
      ..color = const Color(0xFFC48C46)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final trail = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width * 0.75, size.height * 0.6);
    canvas.drawPath(trail, trailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HorseValleyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBF0E4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final hillPaint = Paint()..color = const Color(0xFFB45309);
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.45, size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hillPaint);

    final sunPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.3), 12, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForestCanopyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE6F4EA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final canopy1 = Paint()..color = const Color(0xFF26674B);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.65), 32, canopy1);

    final canopy2 = Paint()..color = const Color(0xFF0F3924);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 36, canopy2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BikeAdventurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF0F5F2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cactusPaint = Paint()
      ..color = const Color(0xFF26674B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.5, size.height), Offset(size.width * 0.5, size.height * 0.3), cactusPaint);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.5), cactusPaint);
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.5), Offset(size.width * 0.35, size.height * 0.4), cactusPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CulturalTraditionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBECE2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final archPaint = Paint()..color = const Color(0xFFB45309);
    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height)
      ..close();
    canvas.drawPath(path, archPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
