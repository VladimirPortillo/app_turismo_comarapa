import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const EventsScreen({super.key, required this.onBack});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Evento> _eventos = <Evento>[];

  // Datos curados representativos de Comarapa en caso de offline o tabla vacía
  static final List<Evento> _demoEventos = [
    Evento(
      id: 'demo-ev-1',
      nombre: 'Feria Nacional del Durazno',
      categoriaNombre: 'Feria',
      descripcion:
          'La festividad productiva más importante de los valles cruceños. Exposición y juzgamiento de las variedades de durazno más selectas, elección de la reina nacional, repostería artesanal comarapeña y conciertos en vivo.',
      fechaInicio: DateTime(2025, 3, 21),
      fechaFin: DateTime(2025, 3, 23),
      periodicidad: 'Anual',
      latitud: -18.0447,
      longitud: -64.5301,
      activo: true,
      imagenes: const [],
    ),
    Evento(
      id: 'demo-ev-2',
      nombre: 'Fiesta Patronal Virgen de la Candelaria',
      categoriaNombre: 'Fiesta patronal',
      descripcion:
          'Solemne conmemoración religiosa de la patrona comarapeña. Misa campal, procesión por las calles coloniales, comparsas tradicionales de danzarines y verbena popular con fuegos de artificio.',
      fechaInicio: DateTime(2025, 2, 1),
      fechaFin: DateTime(2025, 2, 3),
      periodicidad: 'Anual',
      latitud: -18.0435,
      longitud: -64.5290,
      activo: true,
      imagenes: const [],
    ),
    Evento(
      id: 'demo-ev-3',
      nombre: 'Festival del Maíz y Tradición Valluna',
      categoriaNombre: 'Festival',
      descripcion:
          'Encuentro culinario y folclórico en torno a la cosecha del maíz. Elaboración en vivo de humintas, tamales y pasteles al horno de barro, junto a coplas y tonadas tradicionales vallunas.',
      fechaInicio: DateTime(2025, 5, 16),
      fechaFin: DateTime(2025, 5, 18),
      periodicidad: 'Anual',
      latitud: -18.0400,
      longitud: -64.5270,
      activo: true,
      imagenes: const [],
    ),
    Evento(
      id: 'demo-ev-4',
      nombre: 'Encuentro Ecoturístico de los Valles',
      categoriaNombre: 'Cultural',
      descripcion:
          'Jornadas abiertas de senderismo guiado hacia La Pajcha y la Represa La Cañada, observación de fauna silvestre, talleres de conservación ambiental y veladas de fogata campestre.',
      fechaInicio: DateTime(2025, 9, 20),
      fechaFin: DateTime(2025, 9, 21),
      periodicidad: 'Anual',
      latitud: -18.0280,
      longitud: -64.5150,
      activo: true,
      imagenes: const [],
    ),
    Evento(
      id: 'demo-ev-5',
      nombre: 'Aniversario Cívico de Comarapa',
      categoriaNombre: 'Cívico',
      descripcion:
          'Celebración de la fundación de la noble y leal villa de Comarapa. Desfile cívico institucional, sesión de honor del Concejo Municipal, feria artesanal y serenata folclórica.',
      fechaInicio: DateTime(2025, 6, 11),
      fechaFin: DateTime(2025, 6, 11),
      periodicidad: 'Anual',
      latitud: -18.0440,
      longitud: -64.5295,
      activo: true,
      imagenes: const [],
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
      final repo = context.read<EventoRepository>();
      final list = await repo.fetchActivos();
      if (!mounted) return;
      setState(() {
        _eventos = list.isNotEmpty ? list : _demoEventos;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // En caso de modo offline o sin datos en Supabase, cargar los eventos representativos
      setState(() {
        _eventos = _demoEventos;
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final e in _eventos)
        if (e.categoriaNombre != null && e.categoriaNombre!.trim().isNotEmpty)
          e.categoriaNombre!.trim(),
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<Evento> get _filteredEventos {
    final query = _searchQuery.toLowerCase();
    return _eventos.where((e) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || e.categoriaNombre == _selectedCategoria;
      final matchesSearch = e.nombre.toLowerCase().contains(query) ||
          (e.categoriaNombre ?? '').toLowerCase().contains(query) ||
          e.descripcion.toLowerCase().contains(query) ||
          (e.periodicidad ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String categoria, String nombre) {
    final cat = categoria.toLowerCase();
    final name = nombre.toLowerCase();
    if (cat.contains('feria') || name.contains('durazno')) {
      return FairCarnivalPainter();
    } else if (cat.contains('patronal') || name.contains('candelaria') || name.contains('virgen')) {
      return PatronalFeastPainter();
    } else if (cat.contains('festival') || name.contains('música') || name.contains('musica')) {
      return FestivalMusicPainter();
    } else if (cat.contains('cultural') || cat.contains('cívico') || cat.contains('civico')) {
      return CulturalDancePainter();
    } else {
      return EventGenericPainter();
    }
  }

  String _formatFechaRange(DateTime inicio, DateTime? fin) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final mesStr = (inicio.month >= 1 && inicio.month <= 12) ? meses[inicio.month - 1] : '';

    if (fin != null && (fin.day != inicio.day || fin.month != inicio.month)) {
      if (inicio.month == fin.month) {
        return '${inicio.day} - ${fin.day} $mesStr';
      } else {
        final mesFinStr = (fin.month >= 1 && fin.month <= 12) ? meses[fin.month - 1] : '';
        return '${inicio.day} $mesStr - ${fin.day} $mesFinStr';
      }
    }
    return '${inicio.day} $mesStr';
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
            'Eventos y festividades',
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
            hintText: 'Buscar ferias, fiestas patronales, festivales...',
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

    final filtered = _filteredEventos;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildEventoCard(filtered[index]),
            ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    final fechaTexto = _formatFechaRange(evento.fechaInicio, evento.fechaFin);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(evento: evento),
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
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: evento.imagenes.isNotEmpty
                    ? Image.network(
                        evento.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _painterFor(evento.categoriaNombre ?? '', evento.nombre),
                        ),
                      )
                    : CustomPaint(
                        painter: _painterFor(evento.categoriaNombre ?? '', evento.nombre),
                      ),
              ),
              const SizedBox(width: 14),

              // Contenido informativo central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila con categoría y badge de fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2ECE7),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            evento.categoriaNombre ?? 'Festividad',
                            style: const TextStyle(
                              color: Color(0xFF1B5A3F),
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event, size: 12, color: Color(0xFFB45309)),
                              const SizedBox(width: 4),
                              Text(
                                fechaTexto,
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Título del evento
                    Text(
                      evento.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143525),
                        fontFamily: 'serif',
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Frecuencia y lugar
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (evento.periodicidad?.isNotEmpty ?? false)
                              ? evento.periodicidad!
                              : 'Anual',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        const Expanded(
                          child: Text(
                            'Comarapa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha de navegación derecha
              const Padding(
                padding: EdgeInsets.only(left: 6, right: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE2ECE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy,
                size: 44,
                color: Color(0xFF1B5A3F),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron eventos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C3D28),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No hay resultados para "$_searchQuery". Prueba con otro término.'
                  : 'No hay eventos disponibles en esta categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedCategoria != 'Todos') ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategoria = 'Todos';
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5A3F),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// PINTORES VECTORIALES TEMÁTICOS PARA EVENTOS
// -------------------------------------------------------------

/// Ilustración para Ferias frutícolas y agrícolas (Durazno, frutas del valle)
class FairCarnivalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo cielo de valle
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFED7AA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Banderines festivos superiores
    final bannerPaint1 = Paint()..color = const Color(0xFFEF4444);
    final bannerPaint2 = Paint()..color = const Color(0xFF10B981);
    final bannerPaint3 = Paint()..color = const Color(0xFF3B82F6);
    final bannerPaint4 = Paint()..color = const Color(0xFFF59E0B);

    final linePaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bannerPath = Path()
      ..moveTo(0, 10)
      ..quadraticBezierTo(size.width * 0.5, 22, size.width, 12);
    canvas.drawPath(bannerPath, linePaint);

    // Triángulos de banderines
    final banners = [
      [size.width * 0.15, bannerPaint1],
      [size.width * 0.38, bannerPaint2],
      [size.width * 0.62, bannerPaint3],
      [size.width * 0.85, bannerPaint4],
    ];
    for (final b in banners) {
      final x = b[0] as double;
      final p = b[1] as Paint;
      final tri = Path()
        ..moveTo(x - 8, 14)
        ..lineTo(x + 8, 14)
        ..lineTo(x, 26)
        ..close();
      canvas.drawPath(tri, p);
    }

    // Durazno comarapeño central
    final cx = size.width * 0.5;
    final cy = size.height * 0.62;

    // Cuerpo del durazno
    final peachPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFBBF24), Color(0xFFF87171), Color(0xFFDC2626)],
        center: const Alignment(-0.2, -0.2),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 24));
    canvas.drawCircle(Offset(cx - 7, cy), 18, peachPaint);
    canvas.drawCircle(Offset(cx + 7, cy), 18, peachPaint);

    // Tallo y hoja verde
    final stemPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 14), Offset(cx - 2, cy - 22), stemPaint);

    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leafPath = Path()
      ..moveTo(cx, cy - 20)
      ..quadraticBezierTo(cx + 12, cy - 24, cx + 16, cy - 18)
      ..quadraticBezierTo(cx + 8, cy - 14, cx, cy - 20);
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Fiestas Patronales (Virgen de la Candelaria, templo y devoción)
class PatronalFeastPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo cielo atardecer espiritual
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF4C1D95), Color(0xFF831843)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Resplandor dorado circular
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE047).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.45), radius: 36));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 36, haloPaint);

    // Silueta de torre o campanario colonial
    final churchPaint = Paint()..color = const Color(0xFFFBBF24);
    final cx = size.width * 0.5;

    // Cuerpo torre
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 16, size.height * 0.42, 32, size.height * 0.58),
        const Radius.circular(3),
      ),
      churchPaint,
    );

    // Arco de campana
    final archPaint = Paint()..color = const Color(0xFF1E1B4B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 7, size.height * 0.52, 14, 20),
        const Radius.circular(7),
      ),
      archPaint,
    );

    // Campana dorada pequeña
    final bellPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(Offset(cx, size.height * 0.58), 4, bellPaint);

    // Cúpula / cruz superior
    final domePath = Path()
      ..moveTo(cx - 18, size.height * 0.42)
      ..quadraticBezierTo(cx, size.height * 0.30, cx + 18, size.height * 0.42)
      ..close();
    canvas.drawPath(domePath, churchPaint);

    // Cruz superior
    final crossPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(cx, size.height * 0.28), Offset(cx, size.height * 0.20), crossPaint);
    canvas.drawLine(Offset(cx - 5, size.height * 0.24), Offset(cx + 5, size.height * 0.24), crossPaint);

    // Estrellas / chispas
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), 1.8, starPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.22), 2.2, starPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.48), 1.5, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Festivales de Música y Coplas Vallunas
class FestivalMusicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo vibrante de escenario nocturno
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF047857)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Silueta de guitarra / charango acústico
    final cx = size.width * 0.48;
    final cy = size.height * 0.58;

    final guitarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(cx - 20, cy - 20, 40, 45));

    // Curvas del cuerpo de la guitarra
    canvas.drawCircle(Offset(cx, cy + 6), 18, guitarPaint);
    canvas.drawCircle(Offset(cx, cy - 8), 13, guitarPaint);

    // Boca de la guitarra
    final holePaint = Paint()..color = const Color(0xFF451A03);
    canvas.drawCircle(Offset(cx, cy - 4), 6, holePaint);

    // Mástil
    final neckPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(cx, cy - 15), Offset(cx, size.height * 0.18), neckPaint);

    // Clavijero
    canvas.drawRect(Rect.fromLTWH(cx - 5, size.height * 0.12, 10, 8), neckPaint);

    // Notas musicales flotando
    final notePaint = Paint()
      ..color = const Color(0xFF34D399)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final noteFill = Paint()..color = const Color(0xFF34D399);

    // Nota 1
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.32), 4, noteFill);
    canvas.drawLine(
        Offset(size.width * 0.8 + 4, size.height * 0.32),
        Offset(size.width * 0.8 + 4, size.height * 0.18),
        notePaint);
    canvas.drawLine(
        Offset(size.width * 0.8 + 4, size.height * 0.18),
        Offset(size.width * 0.8 + 10, size.height * 0.20),
        notePaint);

    // Nota 2
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.38), 3.5, noteFill);
    canvas.drawLine(
        Offset(size.width * 0.22 + 3.5, size.height * 0.38),
        Offset(size.width * 0.22 + 3.5, size.height * 0.25),
        notePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Eventos Culturales, Cívicos y Danzas
class CulturalDancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo de valles al amanecer
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0C3D28), Color(0xFF1B5A3F), Color(0xFF4ADE80)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Sombrero tradicional valluno
    final cx = size.width * 0.5;
    final cy = size.height * 0.55;

    // Ala del sombrero
    final hatBrimPaint = Paint()..color = const Color(0xFFF3F4F6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: 54, height: 16),
      hatBrimPaint,
    );

    // Copa del sombrero
    final hatCrownPaint = Paint()..color = const Color(0xFFE5E7EB);
    final crownPath = Path()
      ..moveTo(cx - 18, cy + 6)
      ..lineTo(cx - 15, cy - 14)
      ..quadraticBezierTo(cx, cy - 20, cx + 15, cy - 14)
      ..lineTo(cx + 18, cy + 6)
      ..close();
    canvas.drawPath(crownPath, hatCrownPaint);

    // Cinta del sombrero roja/verde
    final ribbonPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRect(Rect.fromLTWH(cx - 17, cy, 34, 4), ribbonPaint);

    // Cintas ondeando festivas
    final rib1 = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final rib2 = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final p1 = Path()
      ..moveTo(cx + 16, cy + 2)
      ..quadraticBezierTo(size.width * 0.8, cy - 10, size.width * 0.88, cy + 8);
    final p2 = Path()
      ..moveTo(cx + 16, cy + 4)
      ..quadraticBezierTo(size.width * 0.75, cy + 14, size.width * 0.84, cy + 24);

    canvas.drawPath(p1, rib1);
    canvas.drawPath(p2, rib2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración genérica de evento / calendario festivo
class EventGenericPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Calendario centrado
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    final calPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 4), width: 42, height: 42),
        const Radius.circular(8),
      ),
      calPaint,
    );

    // Cabecera roja del calendario
    final headerPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(cx, cy - 11), width: 42, height: 12),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      headerPaint,
    );

    // Estrella dorada en el calendario
    final starPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(cx, cy + 10), 6, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
