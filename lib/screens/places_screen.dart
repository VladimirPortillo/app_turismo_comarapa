import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lugar.dart';
import '../models/turismo_tipo.dart';
import '../repositories/lugar_repository.dart';
import 'place_detail_screen.dart';

class PlacesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PlacesScreen({super.key, required this.onBack});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Lugar> _lugares = <Lugar>[];

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
      final lugares = await context.read<LugarRepository>().fetchActivos();
      if (!mounted) return;
      setState(() {
        _lugares = lugares;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final lugar in _lugares)
        if (lugar.categoriaNombre != null) lugar.categoriaNombre!,
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<Lugar> get _filteredLugares {
    final query = _searchQuery.toLowerCase();
    return _lugares.where((lugar) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || lugar.categoriaNombre == _selectedCategoria;
      final matchesSearch = lugar.nombre.toLowerCase().contains(query) ||
          (lugar.categoriaNombre ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String nombre) {
    final name = nombre.toLowerCase();
    if (name.contains('cactus')) {
      return CactusMountainPainter();
    } else if (name.contains('laguna')) {
      return LagunasLeafPainter();
    } else if (name.contains('ruina') || name.contains('fuerte') || name.contains('plaza')) {
      return PrehispanicColumnsPainter();
    } else if (name.contains('puerta') || name.contains('amboró') || name.contains('ave')) {
      return AmboroArchPainter();
    } else {
      return MiradorSerraniaPainter();
    }
  }

  String _tiempoLabel(Lugar lugar) {
    final minutos = lugar.tiempoVisitaMin;
    if (minutos == null) return 'Duración no especificada';
    if (minutos < 60) return '$minutos min';
    final horas = minutos / 60;
    final horasTexto = horas == horas.roundToDouble() ? horas.toInt().toString() : horas.toStringAsFixed(1);
    return '$horasTexto ${horas == 1 ? "hora" : "horas"}';
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

    final filtered = _filteredLugares;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildPlaceCard(filtered[index]),
            ),
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
            'Lugares turísticos',
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
            hintText: 'Buscar un lugar...',
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

  Widget _buildPlaceCard(Lugar lugar) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(lugar: lugar),
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
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: lugar.imagenes.isNotEmpty
                    ? Image.network(
                        lugar.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(painter: _painterFor(lugar.nombre)),
                      )
                    : CustomPaint(painter: _painterFor(lugar.nombre)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2ECE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lugar.categoriaNombre ?? 'Sin categoría',
                        style: const TextStyle(
                          color: Color(0xFF1B5A3F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lugar.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_tiempoLabel(lugar)} · ${dificultadLabel(lugar.dificultad)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No se encontraron lugares',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prueba con otra categoría o término de búsqueda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Custom Painters for Thumbnails ---
// Se mantienen como ilustraciones genéricas mientras no haya fotos reales
// cargadas (el campo `imagenes` de cada lugar sigue siendo la fuente real).

class CactusMountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4E9B7B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final mountainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * -0.1, size.height)
      ..lineTo(size.width * 0.4, size.height * 0.4)
      ..lineTo(size.width * 0.9, size.height)
      ..close();
    canvas.drawPath(path1, mountainPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 1.2, size.height)
      ..close();
    canvas.drawPath(path2, mountainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LagunasLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF539D72);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final leafPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.4, size.width * 0.5, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.4, size.width * 0.5, size.height * 0.5);

    canvas.drawPath(path, leafPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrehispanicColumnsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF75583E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final columnWidth = size.width * 0.12;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.55, columnWidth, size.height * 0.25),
      strokePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.44, size.height * 0.40, columnWidth, size.height * 0.40),
      strokePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.60, size.height * 0.50, columnWidth, size.height * 0.30),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AmboroArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF2E6D4E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.35, size.width * 0.7, size.height * 0.75);
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiradorSerraniaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF72AA8D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..lineTo(size.width * 0.45, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..lineTo(size.width * 0.85, size.height * 0.4)
      ..lineTo(size.width * 0.95, size.height * 0.65);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
