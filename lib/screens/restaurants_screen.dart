import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurante.dart';
import '../repositories/restaurante_repository.dart';
import 'restaurant_detail_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const RestaurantsScreen({super.key, required this.onBack});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Restaurante> _restaurantes = <Restaurante>[];

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
      final repo = context.read<RestauranteRepository>();
      final list = await repo.fetchActivos();
      if (!mounted) return;
      setState(() {
        _restaurantes = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restaurantes = <Restaurante>[];
        _error = 'No se pudieron cargar los restaurantes desde la base de datos.';
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final r in _restaurantes)
        if (r.categoriaNombre != null && r.categoriaNombre!.trim().isNotEmpty)
          r.categoriaNombre!.trim(),
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<Restaurante> get _filteredRestaurantes {
    final query = _searchQuery.toLowerCase();
    return _restaurantes.where((r) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || r.categoriaNombre == _selectedCategoria;
      final matchesSearch = r.nombre.toLowerCase().contains(query) ||
          (r.categoriaNombre ?? '').toLowerCase().contains(query) ||
          r.descripcion.toLowerCase().contains(query) ||
          (r.direccionReferencia ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String categoria, String nombre) {
    final cat = categoria.toLowerCase();
    final name = nombre.toLowerCase();
    if (cat.contains('café') || cat.contains('repostería') || name.contains('durazno')) {
      return CoffeeBakeryPainter();
    } else if (cat.contains('parrilla') || name.contains('asador') || name.contains('chaqueño')) {
      return GrillBarbecuePainter();
    } else if (cat.contains('pizza') || name.contains('beto')) {
      return PizzaPastaPainter();
    } else if (cat.contains('típica') || cat.contains('tipica') || name.contains('fogón')) {
      return TraditionalEateryPainter();
    } else {
      return RestaurantDefaultPainter();
    }
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
            'Restaurantes de Comarapa',
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
            hintText: 'Buscar restaurantes, parrillas, cafés...',
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

    final filtered = _filteredRestaurantes;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildRestauranteCard(filtered[index]),
            ),
    );
  }

  Widget _buildRestauranteCard(Restaurante restaurante) {
    final tieneHorario = restaurante.horarioAtencion != null && restaurante.horarioAtencion!.trim().isNotEmpty;
    final tienePrecio = restaurante.precioReferencial != null && restaurante.precioReferencial! > 0;
    final tieneDireccion = restaurante.direccionReferencia != null && restaurante.direccionReferencia!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurante: restaurante),
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
                child: restaurante.imagenes.isNotEmpty
                    ? Image.network(
                        restaurante.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _painterFor(
                            restaurante.categoriaNombre ?? '',
                            restaurante.nombre,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _painterFor(
                          restaurante.categoriaNombre ?? '',
                          restaurante.nombre,
                        ),
                      ),
              ),
              const SizedBox(width: 14),

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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9EFE5),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            restaurante.categoriaNombre ?? 'Restaurante',
                            style: const TextStyle(
                              color: Color(0xFFC68B59),
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        if (restaurante.calificacionPromedio > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  restaurante.calificacionPromedio.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Nombre del restaurante
                    Text(
                      restaurante.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143525),
                        fontFamily: 'serif',
                      ),
                    ),

                    // Horario y precio aproximado (solo si existen en la BD)
                    if (tieneHorario || tienePrecio) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (tieneHorario) ...[
                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurante.horarioAtencion!.trim(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                          if (tieneHorario && tienePrecio) ...[
                            const SizedBox(width: 8),
                            const Text('·', style: TextStyle(color: Color(0xFF9CA3AF))),
                            const SizedBox(width: 8),
                          ],
                          if (tienePrecio) ...[
                            Text(
                              'Bs ${restaurante.precioReferencial!.toInt()} ref.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5A3F),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Dirección de referencia (solo si existe en la BD)
                    if (tieneDireccion) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              restaurante.direccionReferencia!.trim(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Flecha de navegación derecha
              const Padding(
                padding: EdgeInsets.only(left: 4, right: 2),
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
                color: Color(0xFFF9EFE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 44,
                color: Color(0xFFC68B59),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron restaurantes',
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
                  ? 'No hay restaurantes que coincidan con "$_searchQuery".'
                  : 'No hay opciones disponibles en esta categoría.',
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
// PINTORES VECTORIALES TEMÁTICOS PARA RESTAURANTES
// -------------------------------------------------------------

/// Ilustración para Comida Típica (Fogón valluno, olla de barro y leña)
class TraditionalEateryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A), Color(0xFFFCD34D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width * 0.5;
    final cy = size.height * 0.55;

    // Fogón de ladrillo / leña
    final woodPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 20, cy + 24), Offset(cx + 18, cy + 28), woodPaint);
    canvas.drawLine(Offset(cx - 18, cy + 28), Offset(cx + 20, cy + 24), woodPaint);

    // Llamas de leña
    final flamePaint = Paint()..color = const Color(0xFFEA580C);
    final flamePath = Path()
      ..moveTo(cx - 10, cy + 22)
      ..quadraticBezierTo(cx - 4, cy + 8, cx, cy + 2)
      ..quadraticBezierTo(cx + 4, cy + 8, cx + 10, cy + 22)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    // Olla de barro tradicional
    final potPaint = Paint()..color = const Color(0xFF9A3412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 44, height: 30),
      potPaint,
    );

    // Tapa de la olla
    final lidPaint = Paint()..color = const Color(0xFF7C2D12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 10), width: 40, height: 10),
      lidPaint,
    );
    canvas.drawCircle(Offset(cx, cy - 14), 4, lidPaint);

    // Asas de la olla
    final handlePaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 22, cy + 2), width: 10, height: 12),
      -1.5,
      3.0,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 22, cy + 2), width: 10, height: 12),
      1.5,
      3.0,
      false,
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Parrillas y Asadores (Brasas y cortes a la leña)
class GrillBarbecuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1C1917), Color(0xFF44403C), Color(0xFF78350F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width * 0.5;
    final cy = size.height * 0.55;

    // Resplandor de brasas
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy + 15), radius: 30));
    canvas.drawCircle(Offset(cx, cy + 15), 30, glowPaint);

    // Rejilla de parrilla
    final grillPaint = Paint()
      ..color = const Color(0xFFD6D3D1)
      ..strokeWidth = 2;
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(
        Offset(cx + (i * 8), cy - 10),
        Offset(cx + (i * 8), cy + 18),
        grillPaint,
      );
    }
    canvas.drawLine(Offset(cx - 28, cy - 2), Offset(cx + 28, cy - 2), grillPaint);
    canvas.drawLine(Offset(cx - 28, cy + 10), Offset(cx + 28, cy + 10), grillPaint);

    // Brocheta / Pacumuto o corte de carne
    final meatPaint = Paint()..color = const Color(0xFF991B1B);
    final skewerPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(cx - 26, cy + 24), Offset(cx + 26, cy - 18), skewerPaint);
    canvas.drawCircle(Offset(cx - 10, cy + 10), 6, meatPaint);
    canvas.drawCircle(Offset(cx, cy + 2), 7, meatPaint);
    canvas.drawCircle(Offset(cx + 10, cy - 6), 6, meatPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Café & Repostería de Durazno
class CoffeeBakeryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA), Color(0xFFFDBA74)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width * 0.48;
    final cy = size.height * 0.58;

    // Plato taza
    final saucerPaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 18), width: 56, height: 10),
      saucerPaint,
    );

    // Taza de café
    final cupPaint = Paint()..color = const Color(0xFF854D0E);
    final cupPath = Path()
      ..moveTo(cx - 18, cy - 4)
      ..lineTo(cx - 14, cy + 16)
      ..quadraticBezierTo(cx, cy + 18, cx + 14, cy + 16)
      ..lineTo(cx + 18, cy - 4)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Asa de la taza
    final handlePaint = Paint()
      ..color = const Color(0xFF854D0E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 20, cy + 5), width: 12, height: 14),
      -1.5,
      3.0,
      false,
      handlePaint,
    );

    // Vapor ondulante
    final steamPaint = Paint()
      ..color = const Color(0xFFB45309).withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final steam1 = Path()
      ..moveTo(cx - 6, cy - 8)
      ..quadraticBezierTo(cx - 12, cy - 18, cx - 6, cy - 26);
    final steam2 = Path()
      ..moveTo(cx + 6, cy - 8)
      ..quadraticBezierTo(cx + 12, cy - 18, cx + 6, cy - 26);

    canvas.drawPath(steam1, steamPaint);
    canvas.drawPath(steam2, steamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración para Pizzería y Trattoria
class PizzaPastaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2), Color(0xFFFECACA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width * 0.5;
    final cy = size.height * 0.52;

    // Rebanada de pizza triangular
    final crustPaint = Paint()..color = const Color(0xFFB45309);
    final cheesePaint = Paint()..color = const Color(0xFFFBBF24);

    // Corteza
    final slicePath = Path()
      ..moveTo(cx, cy - 24)
      ..lineTo(cx + 24, cy + 22)
      ..quadraticBezierTo(cx, cy + 26, cx - 24, cy + 22)
      ..close();
    canvas.drawPath(slicePath, cheesePaint);

    final arcPath = Path()
      ..moveTo(cx - 24, cy + 22)
      ..quadraticBezierTo(cx, cy + 28, cx + 24, cy + 22)
      ..lineTo(cx + 24, cy + 26)
      ..quadraticBezierTo(cx, cy + 32, cx - 24, cy + 26)
      ..close();
    canvas.drawPath(arcPath, crustPaint);

    // Ingredientes (rodajas de tomate / queso criollo)
    final topPaint1 = Paint()..color = const Color(0xFFDC2626);
    final topPaint2 = Paint()..color = const Color(0xFF15803D);

    canvas.drawCircle(Offset(cx - 4, cy + 6), 5, topPaint1);
    canvas.drawCircle(Offset(cx + 8, cy + 12), 4.5, topPaint1);
    canvas.drawCircle(Offset(cx + 3, cy - 6), 4, topPaint1);

    // Hojas de albahaca
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, cy + 14), width: 7, height: 4),
      topPaint2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, cy + 2), width: 6, height: 3.5),
      topPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ilustración genérica de restaurante / tenedor y cuchillo
class RestaurantDefaultPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Plato
    final platePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 24, platePaint);

    final rimPaint = Paint()
      ..color = const Color(0xFFC68B59)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), 24, rimPaint);

    // Cloche / campana central
    final innerPaint = Paint()..color = const Color(0xFFF9EFE5);
    canvas.drawCircle(Offset(cx, cy), 16, innerPaint);

    // Cubiertos
    final cutleryPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 32, cy - 14), Offset(cx - 32, cy + 14), cutleryPaint);
    canvas.drawLine(Offset(cx + 32, cy - 14), Offset(cx + 32, cy + 14), cutleryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
