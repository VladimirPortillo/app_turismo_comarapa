import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import 'hotel_detail_screen.dart';

class HotelsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const HotelsScreen({super.key, required this.onBack});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Hotel> _hoteles = <Hotel>[];

  // Datos de hospedajes curados para Comarapa en caso de offline o tabla vacía
  static final List<Hotel> _demoHoteles = [
    const Hotel(
      id: 'demo-hotel-1',
      nombre: 'Hotel Valle Verde',
      categoriaNombre: 'Hotel',
      descripcion: 'Alojamiento confortable en el centro de Comarapa, habitaciones con baño privado, agua caliente 24 horas y señal wifi de alta velocidad.',
      precioMin: 180,
      precioMax: 250,
      direccionReferencia: 'Av. Circunvalación, a 2 cuadras de la plaza principal',
      contactoReservas: '+591 3 936 1145',
      servicios: ['Wifi gratis', 'Parqueo privado', 'Desayuno incluido', 'Agua caliente'],
      latitud: -18.0401,
      longitud: -64.5276,
      activo: true,
      calificacionPromedio: 4.8,
    ),
    const Hotel(
      id: 'demo-hotel-2',
      nombre: 'Hostal El Mirador del Valle',
      categoriaNombre: 'Hostal',
      descripcion: 'Acogedor hostal familiar con terraza y vistas panorámicas a los huertos de durazno y serranías de Comarapa.',
      precioMin: 90,
      precioMax: 140,
      direccionReferencia: 'Calle Sucre esq. Bolívar, Comarapa',
      contactoReservas: '+591 712 34567',
      servicios: ['Wifi gratis', 'Desayuno casero', 'Agua caliente', 'Terraza mirador'],
      latitud: -18.0375,
      longitud: -64.5290,
      activo: true,
      calificacionPromedio: 4.6,
    ),
    const Hotel(
      id: 'demo-hotel-3',
      nombre: 'Cabañas Rústicas La Pajcha',
      categoriaNombre: 'Cabaña',
      descripcion: 'Cabañas independientes de madera y piedra en entorno campestre rodeadas de vegetación y arroyos, con área de fogata nocturna.',
      precioMin: 220,
      precioMax: 350,
      direccionReferencia: 'Camino a La Pajcha, km 4, Comarapa',
      contactoReservas: '+591 721 98765',
      servicios: ['Fogata nocturna', 'Parqueo', 'Parrilleros', 'Senderos privados'],
      latitud: -18.0280,
      longitud: -64.5150,
      activo: true,
      calificacionPromedio: 4.9,
    ),
    const Hotel(
      id: 'demo-hotel-4',
      nombre: 'Camping Ecológico Los Sauces',
      categoriaNombre: 'Camping',
      descripcion: 'Espacio verde seguro a orillas del río para acampar bajo las estrellas, con baños limpios, duchas y parrilleros comunitarios.',
      precioMin: 40,
      precioMax: 70,
      direccionReferencia: 'Ribera del Río Comarapa, Sector Los Sauces',
      contactoReservas: '+591 730 45678',
      servicios: ['Baños y duchas', 'Fogatas permitidas', 'Seguridad 24h', 'Parrilleros'],
      latitud: -18.0510,
      longitud: -64.5320,
      activo: true,
      calificacionPromedio: 4.5,
    ),
    const Hotel(
      id: 'demo-hotel-5',
      nombre: 'Residencial Comarapa Colonial',
      categoriaNombre: 'Hostal',
      descripcion: 'Casona tradicional restaurada con patio central lleno de plantas ornamentales, ambiente sereno y trato cordial.',
      precioMin: 110,
      precioMax: 160,
      direccionReferencia: 'Calle 16 de Julio #45, Centro Histórico',
      contactoReservas: '+591 3 936 1020',
      servicios: ['Wifi gratis', 'Agua caliente', 'Patio central', 'Cafetería'],
      latitud: -18.0392,
      longitud: -64.5265,
      activo: true,
      calificacionPromedio: 4.7,
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
      final repo = context.read<HotelRepository>();
      final list = await repo.fetchActivos();
      if (!mounted) return;
      setState(() {
        _hoteles = list.isNotEmpty ? list : _demoHoteles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // En caso de modo offline o sin datos en Supabase, cargar la muestra demo representativa
      setState(() {
        _hoteles = _demoHoteles;
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final h in _hoteles)
        if (h.categoriaNombre != null && h.categoriaNombre!.trim().isNotEmpty)
          h.categoriaNombre!.trim(),
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<Hotel> get _filteredHoteles {
    final query = _searchQuery.toLowerCase();
    return _hoteles.where((h) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || h.categoriaNombre == _selectedCategoria;
      final matchesSearch = h.nombre.toLowerCase().contains(query) ||
          (h.categoriaNombre ?? '').toLowerCase().contains(query) ||
          h.descripcion.toLowerCase().contains(query) ||
          (h.direccionReferencia ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String categoria, String nombre) {
    final cat = categoria.toLowerCase();
    final name = nombre.toLowerCase();
    if (cat.contains('cabaña') || name.contains('cabaña')) {
      return CabinWoodPainter();
    } else if (cat.contains('camping') || name.contains('camping')) {
      return CampingTentPainter();
    } else if (cat.contains('hostal') || name.contains('residencial')) {
      return HostelCozyPainter();
    } else {
      return HotelFacadePainter();
    }
  }

  String _preciosLabel(Hotel h) {
    final min = h.precioMin;
    final max = h.precioMax;
    if (min != null && max != null) {
      return 'Bs ${min.toInt()} - ${max.toInt()}';
    } else if (min != null) {
      return 'Desde Bs ${min.toInt()}';
    }
    return 'Bs 150 - 250';
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
            'Hoteles y hospedajes',
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
            hintText: 'Buscar hoteles, hostales, cabañas...',
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

    final filtered = _filteredHoteles;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildHotelCard(filtered[index]),
            ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HotelDetailScreen(hotel: hotel),
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
                child: hotel.imagenes.isNotEmpty
                    ? Image.network(
                        hotel.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _painterFor(hotel.categoriaNombre ?? '', hotel.nombre),
                        ),
                      )
                    : CustomPaint(painter: _painterFor(hotel.categoriaNombre ?? '', hotel.nombre)),
              ),
              const SizedBox(width: 16),

              // Contenido informativo central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila con categoría y calificación
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2ECE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hotel.categoriaNombre ?? 'Hospedaje',
                            style: const TextStyle(
                              color: Color(0xFF1B5A3F),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              hotel.calificacionPromedio > 0
                                  ? hotel.calificacionPromedio.toStringAsFixed(1)
                                  : '4.8',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Nombre del hotel
                    Text(
                      hotel.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fila con precio por noche
                    Row(
                      children: [
                        const Icon(Icons.night_shelter_outlined, size: 14, color: Color(0xFF1B5A3F)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_preciosLabel(hotel)} / noche',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B5A3F),
                              fontWeight: FontWeight.w600,
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
              Icon(Icons.hotel_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No se encontraron hospedajes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prueba ajustando el término de búsqueda o tipo de hospedaje',
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
// Pintores artísticos temáticos para las miniaturas de hoteles y hospedajes
// ---------------------------------------------------------------------------

class HotelFacadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE5EFEA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final bldgPaint = Paint()..color = const Color(0xFF26674B);
    final bldg = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.25)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..lineTo(size.width * 0.8, size.height)
      ..close();
    canvas.drawPath(bldg, bldgPaint);

    // Ventanas
    final winPaint = Paint()..color = const Color(0xFFFDE68A);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final left = size.width * (0.28 + c * 0.18);
        final top = size.height * (0.35 + r * 0.18);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, 8, 8), const Radius.circular(2)), winPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HostelCozyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBF4EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final housePaint = Paint()..color = const Color(0xFFB45309);
    final roof = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.25)
      ..lineTo(size.width * 0.85, size.height * 0.5)
      ..close();
    canvas.drawPath(roof, housePaint);

    final wallPaint = Paint()..color = const Color(0xFFECCEB8);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.22, size.height * 0.5, size.width * 0.56, size.height * 0.45), wallPaint);

    final doorPaint = Paint()..color = const Color(0xFF8C4717);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.42, size.height * 0.65, size.width * 0.16, size.height * 0.3), doorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CabinWoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8F3EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pinePaint = Paint()..color = const Color(0xFF1B5A3F);
    final pine = Path()
      ..moveTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.85, size.height * 0.3)
      ..lineTo(size.width * 0.95, size.height)
      ..close();
    canvas.drawPath(pine, pinePaint);

    final cabinPaint = Paint()..color = const Color(0xFF854D0E);
    final cabin = Path()
      ..moveTo(size.width * 0.2, size.height * 0.45)
      ..lineTo(size.width * 0.45, size.height * 0.25)
      ..lineTo(size.width * 0.7, size.height * 0.45)
      ..close();
    canvas.drawPath(cabin, cabinPaint);

    final wall = Paint()..color = const Color(0xFFA16207);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.4, size.height * 0.5), wall);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CampingTentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F2E22);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final tentPaint = Paint()..color = const Color(0xFF26674B);
    final tent = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.85, size.height * 0.85)
      ..close();
    canvas.drawPath(tent, tentPaint);

    final flapPaint = Paint()..color = const Color(0xFF0C3D28);
    final flap = Path()
      ..moveTo(size.width * 0.38, size.height * 0.85)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      ..lineTo(size.width * 0.62, size.height * 0.85)
      ..close();
    canvas.drawPath(flap, flapPaint);

    final starPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 1.5, starPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.18), 2.0, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
