import 'package:flutter/material.dart';

class Place {
  final String name;
  final String category;
  final String time;
  final String difficulty;
  final CustomPainter Function() imagePainterBuilder;
  final Color badgeBgColor;
  final Color badgeTextColor;

  Place({
    required this.name,
    required this.category,
    required this.time,
    required this.difficulty,
    required this.imagePainterBuilder,
    required this.badgeBgColor,
    required this.badgeTextColor,
  });
}

class PlacesScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PlacesScreen({super.key, required this.onBack});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  final List<String> _categories = [
    'Todos',
    'Natural',
    'Arqueológico',
    'Aventura',
    'Mirador',
  ];

  late final List<Place> _allPlaces;

  @override
  void initState() {
    super.initState();
    _allPlaces = [
      Place(
        name: 'Valle de los Cactus',
        category: 'Natural',
        time: '2 horas',
        difficulty: 'Fácil',
        badgeBgColor: const Color(0xFFE2ECE7),
        badgeTextColor: const Color(0xFF1B5A3F),
        imagePainterBuilder: () => CactusMountainPainter(),
      ),
      Place(
        name: 'Jardín de Lagunas',
        category: 'Natural',
        time: '3 horas',
        difficulty: 'Media',
        badgeBgColor: const Color(0xFFE2ECE7),
        badgeTextColor: const Color(0xFF1B5A3F),
        imagePainterBuilder: () => LagunasLeafPainter(),
      ),
      Place(
        name: 'Ruinas prehispánicas',
        category: 'Arqueológico',
        time: '1.5 horas',
        difficulty: 'Fácil',
        badgeBgColor: const Color(0xFFF9EFE5),
        badgeTextColor: const Color(0xFFC68B59),
        imagePainterBuilder: () => PrehispanicColumnsPainter(),
      ),
      Place(
        name: 'Puerta al Amboró',
        category: 'Aventura',
        time: 'Medio día',
        difficulty: 'Media',
        badgeBgColor: const Color(0xFFE2ECE7),
        badgeTextColor: const Color(0xFF1B5A3F),
        imagePainterBuilder: () => AmboroArchPainter(),
      ),
      Place(
        name: 'Mirador Serranía',
        category: 'Mirador',
        time: '1 hora',
        difficulty: 'Fácil',
        badgeBgColor: const Color(0xFFE2ECE7),
        badgeTextColor: const Color(0xFF1B5A3F),
        imagePainterBuilder: () => MiradorSerraniaPainter(),
      ),
    ];

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Place> get _filteredPlaces {
    return _allPlaces.where((place) {
      final matchesCategory = _selectedCategory == 'Todos' || place.category == _selectedCategory;
      final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildSearchBar(),
        const SizedBox(height: 20),
        _buildCategoriesSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final place = filtered[index];
                    return _buildPlaceCard(place);
                  },
                ),
        ),
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
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
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
                  setState(() {
                    _selectedCategory = category;
                  });
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

  Widget _buildPlaceCard(Place place) {
    return Container(
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
            // Thumbnail with custom illustrations
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: place.imagePainterBuilder(),
              ),
            ),
            const SizedBox(width: 16),
            // Place text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: place.badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      place.category,
                      style: TextStyle(
                        color: place.badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time / Difficulty metadata
                  Row(
                    children: [
                      Icon(Icons.access_time_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${place.time} · ${place.difficulty}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }
}

// --- Custom Painters for Thumbnails ---

class CactusMountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background color (Natural - Medium green)
    paint.color = const Color(0xFF4E9B7B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Mountain silhouettes in white with opacity
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

    // Background color (Natural - Sage green)
    paint.color = const Color(0xFF539D72);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Minimalist leaf outline in white
    final leafPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Leaf / plant bud outline
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height * 0.5) // Stem
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.4, size.width * 0.5, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.4, size.width * 0.5, size.height * 0.5);

    canvas.drawPath(path, leafPaint);

    // Small droplet or dot inside/around
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrehispanicColumnsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background color (Arqueologico - Earth Brown)
    paint.color = const Color(0xFF75583E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Rectangular ruins outline in white
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final columnWidth = size.width * 0.12;

    // Draw three columns next to each other
    // Column 1
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.55, columnWidth, size.height * 0.25),
      strokePaint,
    );
    // Column 2
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.44, size.height * 0.40, columnWidth, size.height * 0.40),
      strokePaint,
    );
    // Column 3
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

    // Background color (Aventura - Dark Forest Green)
    paint.color = const Color(0xFF2E6D4E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Arch outline and mountain peak
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.35, size.width * 0.7, size.height * 0.75);
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiradorSerraniaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background color (Mirador - Soft Mint Green)
    paint.color = const Color(0xFF72AA8D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // White outline mountain lines
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
