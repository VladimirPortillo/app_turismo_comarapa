import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lugar.dart';
import '../repositories/lugar_repository.dart';
import 'auth_gate.dart';
import 'place_detail_screen.dart';
import 'places_screen.dart';
import 'activities_screen.dart';
import 'gastronomy_screen.dart';
import 'hotels_screen.dart';
import 'events_screen.dart';
import 'restaurants_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Lugar> _destacados = <Lugar>[];
  bool _loadingDestacados = true;

  @override
  void initState() {
    super.initState();
    _loadDestacados();
  }

  Future<void> _loadDestacados() async {
    try {
      final lugares = await context.read<LugarRepository>().fetchActivos();
      if (!mounted) return;
      setState(() {
        _destacados = lugares.take(5).toList();
        _loadingDestacados = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDestacados = false);
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildHeroBanner(),
                const SizedBox(height: 28),
                _buildCategoriesSection(),
                const SizedBox(height: 28),
                _buildHighlightsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      case 1:
        return SafeArea(
          child: PlacesScreen(
            onBack: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
        );
      case 2:
        return const MapScreen();
      case 3:
        return SafeArea(
          child: EventsScreen(
            onBack: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
        );
      case 4:
        return _buildPlaceholderTab('Más');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholderTab(String title) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C3D28),
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Esta sección está en desarrollo',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1B5A3F),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place_outlined),
            label: 'Lugares',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CustomPaint(
              size: const Size(24, 20),
              painter: GreenMountainLogoPainter(),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MUNICIPIO DE',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Comarapa',
                  style: TextStyle(
                    color: Color(0xFF0C3D28),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'serif',
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AuthGate()),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE2ECE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFF0C3D28),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
        decoration: InputDecoration(
          hintText: 'Buscar lugares, hoteles, eventos...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: BannerBackgroundPainter(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'EL PARAÍSO ESCONDIDO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bienvenido\na Comarapa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      fontFamily: 'serif',
                      height: 1.15,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _currentIndex = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0C3D28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explorar lugares',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explorar por categoría',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C3D28),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            _buildCategoryCard('Lugares', Icons.location_on_outlined, const Color(0xFFE8F3EF), const Color(0xFF1B5A3F)),
            _buildCategoryCard('Actividades', Icons.explore_outlined, const Color(0xFFE8F3EF), const Color(0xFF1B5A3F)),
            _buildCategoryCard('Gastronomía', Icons.restaurant_menu_outlined, const Color(0xFFF9EFE5), const Color(0xFFC68B59)),
            _buildCategoryCard('Hoteles', Icons.business_center_outlined, const Color(0xFFE8F3EF), const Color(0xFF1B5A3F)),
            _buildCategoryCard('Eventos', Icons.calendar_today_outlined, const Color(0xFFE8F3EF), const Color(0xFF1B5A3F)),
            _buildCategoryCard('Restaurantes', Icons.home_outlined, const Color(0xFFF9EFE5), const Color(0xFFC68B59)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String label, IconData icon, Color bgColor, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (label == 'Lugares') {
          setState(() {
            _currentIndex = 1;
          });
        } else if (label == 'Actividades') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFFFAF9F6),
                body: SafeArea(
                  child: ActivitiesScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          );
        } else if (label == 'Gastronomía') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFFFAF9F6),
                body: SafeArea(
                  child: GastronomyScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          );
        } else if (label == 'Hoteles') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFFFAF9F6),
                body: SafeArea(
                  child: HotelsScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          );
        } else if (label == 'Eventos') {
          setState(() {
            _currentIndex = 3;
          });
        } else if (label == 'Restaurantes') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFFFAF9F6),
                body: SafeArea(
                  child: RestaurantsScreen(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Destacados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C3D28),
                fontFamily: 'serif',
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 1);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D52),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: _buildHighlightsBody(),
        ),
      ],
    );
  }

  Widget _buildHighlightsBody() {
    if (_loadingDestacados) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5A3F)),
        ),
      );
    }

    if (_destacados.isEmpty) {
      return Center(
        child: Text(
          'Todavía no hay lugares cargados.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _destacados.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) => _buildHighlightCard(_destacados[index]),
    );
  }

  Widget _buildHighlightCard(Lugar lugar) {
    final imageUrl = lugar.imagenes.isNotEmpty ? lugar.imagenes.first : null;
    final title = lugar.nombre;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(lugar: lugar),
          ),
        );
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF26674B), Color(0xFF0C3D28)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF26674B), Color(0xFF0C3D28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GreenMountainLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5A3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.85);
    path.lineTo(size.width * 0.4, size.height * 0.25);
    path.lineTo(size.width * 0.62, size.height * 0.7);
    path.lineTo(size.width * 0.82, size.height * 0.45);
    path.lineTo(size.width * 0.95, size.height * 0.8);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = const Color(0xFF1B5A3F)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.35), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BannerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Solid dark green
    paint.color = const Color(0xFF26674B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Mountain silhouettes in banner background
    paint.color = Colors.white.withValues(alpha: 0.04);
    final path1 = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.75, size.height * 0.35)
      ..lineTo(size.width * 1.0, size.height)
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = Colors.white.withValues(alpha: 0.06);
    final path2 = Path()
      ..moveTo(size.width * 0.6, size.height)
      ..lineTo(size.width * 0.85, size.height * 0.2)
      ..lineTo(size.width * 1.1, size.height)
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
