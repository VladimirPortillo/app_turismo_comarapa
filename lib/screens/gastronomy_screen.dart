import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../repositories/gastronomia_repository.dart';
import 'gastronomy_detail_screen.dart';

class GastronomyScreen extends StatefulWidget {
  final VoidCallback onBack;

  const GastronomyScreen({super.key, required this.onBack});

  @override
  State<GastronomyScreen> createState() => _GastronomyScreenState();
}

class _GastronomyScreenState extends State<GastronomyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoria = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<GastronomiaItem> _items = <GastronomiaItem>[];

  // Datos gastronómicos emblemáticos de Comarapa como fallback offline o tabla vacía
  static final List<GastronomiaItem> _demoItems = [
    GastronomiaItem(
      id: 'demo-gastro-1',
      nombre: 'Picante de Pollo con Durazno',
      categoriaNombre: 'Platos típicos',
      descripcion: 'El plato insignia de Comarapa: pollo criollo cocinado a fuego lento en ají colorado comarapeño, servido con duraznos caramelizados del valle, papa y arroz.',
      temporada: 'Todo el año',
      precioReferencial: 40,
      activo: true,
    ),
    GastronomiaItem(
      id: 'demo-gastro-2',
      nombre: 'Pique Macho Comarapeño',
      categoriaNombre: 'Platos típicos',
      descripcion: 'Generosa porción de lomo de res tierno salteado con salchichas, papas fritas crocantes, huevo duro, tomate y locoto fresco cosechado en los huertos comarapeños.',
      temporada: 'Todo el año',
      precioReferencial: 55,
      activo: true,
    ),
    GastronomiaItem(
      id: 'demo-gastro-3',
      nombre: 'Empanadas Blanqueadas',
      categoriaNombre: 'Postres & Dulces',
      descripcion: 'Tradición repostera de los valles cruceños: masa crujiente rellena con dulce casero de cayote y cubierta con una capa suave de merengue blanqueado.',
      temporada: 'Todo el año',
      precioReferencial: 5,
      activo: true,
    ),
    GastronomiaItem(
      id: 'demo-gastro-4',
      nombre: 'Mermelada Artesanal de Durazno',
      categoriaNombre: 'Postres & Dulces',
      descripcion: 'Confitura natural elaborada con duraznos selectos de la cosecha de Comarapa, cocinada en pailas de cobre con azúcar morena y sin aditivos químicos.',
      temporada: 'Enero - Mayo',
      precioReferencial: 25,
      activo: true,
    ),
    GastronomiaItem(
      id: 'demo-gastro-5',
      nombre: 'Licor Tradicional de Durazno',
      categoriaNombre: 'Bebidas & Licores',
      descripcion: 'Macerado artesanal elaborado a base de aguardiente puro y pulpa de duraznos madurados al sol en los valles, con aromas dulces y notas especiadas.',
      temporada: 'Todo el año',
      precioReferencial: 45,
      activo: true,
    ),
    GastronomiaItem(
      id: 'demo-gastro-6',
      nombre: 'Sopa de Maní con Macarrón',
      categoriaNombre: 'Platos típicos',
      descripcion: 'Entrada caliente reconfortante a base de maní tostado y molido en batán, con trozos de carne de res, papas pai doradas y perejil fresco.',
      temporada: 'Todo el año',
      precioReferencial: 25,
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
      final repo = context.read<GastronomiaRepository>();
      final list = await repo.fetchActivos();
      if (!mounted) return;
      setState(() {
        _items = list.isNotEmpty ? list : _demoItems;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // En caso de modo offline o sin datos en Supabase, cargar la muestra demo representativa
      setState(() {
        _items = _demoItems;
        _loading = false;
      });
    }
  }

  List<String> get _categorias {
    final nombres = <String>{
      for (final item in _items)
        if (item.categoriaNombre != null && item.categoriaNombre!.trim().isNotEmpty)
          item.categoriaNombre!.trim(),
    }.toList()
      ..sort();
    return ['Todos', ...nombres];
  }

  List<GastronomiaItem> get _filteredItems {
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      final matchesCategory =
          _selectedCategoria == 'Todos' || item.categoriaNombre == _selectedCategoria;
      final matchesSearch = item.nombre.toLowerCase().contains(query) ||
          (item.categoriaNombre ?? '').toLowerCase().contains(query) ||
          item.descripcion.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CustomPainter _painterFor(String nombre) {
    final name = nombre.toLowerCase();
    if (name.contains('picante') || name.contains('pique') || name.contains('sopa')) {
      return TraditionalDishPainter();
    } else if (name.contains('mermelada') || name.contains('dulce') || name.contains('durazno')) {
      return PeachDessertPainter();
    } else if (name.contains('licor') || name.contains('bebida')) {
      return ArtisanalLiquorPainter();
    } else {
      return BakeryPastryPainter();
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
            'Gastronomía tradicional',
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
            hintText: 'Buscar platos, postres, licores...',
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
              selectedColor: const Color(0xFFB45309),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFB45309) : Colors.grey.shade200,
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

    final filtered = _filteredItems;

    return RefreshIndicator(
      onRefresh: _load,
      child: filtered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildGastronomyCard(filtered[index]),
            ),
    );
  }

  Widget _buildGastronomyCard(GastronomiaItem item) {
    final precio = item.precioReferencial;
    final precioTexto = precio != null && precio > 0 ? 'Bs ${precio.toInt()}' : 'Bs 30';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GastronomyDetailScreen(item: item),
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
              // Miniatura ilustrada o imagen de foto
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imagenes.isNotEmpty
                    ? Image.network(
                        item.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _painterFor(item.nombre),
                        ),
                      )
                    : CustomPaint(painter: _painterFor(item.nombre)),
              ),
              const SizedBox(width: 16),

              // Contenido informativo central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBECE2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.categoriaNombre ?? 'Tradición',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Nombre del plato
                    Text(
                      item.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fila con temporada y precio
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.temporada?.isNotEmpty == true
                                ? item.temporada!
                                : 'Todo el año',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF4EC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFECCEB8)),
                          ),
                          child: Text(
                            precioTexto,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
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
              Icon(Icons.restaurant_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No se encontraron platos o delicias',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prueba con otra palabra clave o categoría',
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
// Pintores artísticos temáticos para las miniaturas gastronómicas
// ---------------------------------------------------------------------------

class TraditionalDishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBF4EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final platePaint = Paint()..color = const Color(0xFFECCEB8);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.52), 34, platePaint);

    final foodPaint = Paint()..color = const Color(0xFFB45309);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.52), 24, foodPaint);

    final garnishPaint = Paint()..color = const Color(0xFF16A34A);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), 6, garnishPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PeachDessertPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFFF7ED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final peachPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.56), 26, peachPaint);

    final leafPaint = Paint()..color = const Color(0xFF16A34A);
    final leaf = Path()
      ..moveTo(size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.25, size.width * 0.7, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.4, size.width * 0.5, size.height * 0.35);
    canvas.drawPath(leaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArtisanalLiquorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFAF2E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final bottlePaint = Paint()
      ..color = const Color(0xFFB45309)
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;
    
    final bottle = Path()
      ..moveTo(size.width * 0.4, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.45)
      ..lineTo(size.width * 0.7, size.height * 0.55)
      ..lineTo(size.width * 0.7, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.45)
      ..close();
    canvas.drawPath(bottle, bottlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BakeryPastryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFFFBEB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pastryPaint = Paint()..color = const Color(0xFFD97706);
    final pastry = Path()
      ..moveTo(size.width * 0.25, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.25, size.width * 0.75, size.height * 0.65)
      ..close();
    canvas.drawPath(pastry, pastryPaint);

    final glazePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 10, glazePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
