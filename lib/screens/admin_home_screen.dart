import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/preferences_controller.dart';
import '../widgets/mode_banner.dart';
import 'about_adaptation_screen.dart';
import 'context/context_lab_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'places_screen.dart';
import 'edit_place_screen.dart';

class AdminPlace {
  String name;
  String category;
  String mainCategory;
  bool isActive;
  String? description;
  String? difficulty;
  String? estimatedTime;
  String? entryCost;
  String? bestSeason;
  double? latitude;
  double? longitude;

  AdminPlace({
    required this.name,
    required this.category,
    required this.mainCategory,
    required this.isActive,
    this.description,
    this.difficulty = 'Fácil',
    this.estimatedTime = '2 horas',
    this.entryCost = 'Gratuito',
    this.bestSeason = 'Abril – Octubre',
    this.latitude = -17.9145,
    this.longitude = -64.4818,
  });
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedMainCategory = 'Lugares';
  String _selectedStatusFilter = 'Todos';
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _mainCategories = [
    'Lugares',
    'Actividades',
    'Gastronomía',
    'Hoteles',
  ];

  final List<AdminPlace> _places = [
    // Lugares
    AdminPlace(
      name: 'Valle de los Cactus',
      category: 'Natural',
      mainCategory: 'Lugares',
      isActive: true,
      description: 'Un mirador natural donde crecen decenas de especies de cactáceas junto a formaciones rocosas únicas...',
      difficulty: 'Fácil',
      estimatedTime: '2 horas',
      entryCost: 'Gratuito',
      bestSeason: 'Abril – Octubre',
      latitude: -17.9145,
      longitude: -64.4818,
    ),
    AdminPlace(
      name: 'Jardín de Lagunas',
      category: 'Natural',
      mainCategory: 'Lugares',
      isActive: true,
      description: 'Hermoso sendero ecológico rodeado de lagunas naturales cristalinas y abundante vegetación local.',
      difficulty: 'Media',
      estimatedTime: '3 horas',
      entryCost: '10 Bs.',
      bestSeason: 'Todo el año',
      latitude: -17.9250,
      longitude: -64.4920,
    ),
    AdminPlace(
      name: 'Ruinas prehispánicas',
      category: 'Arqueológico',
      mainCategory: 'Lugares',
      isActive: true,
      description: 'Asentamientos y terrazas arqueológicas precolombinas que muestran la historia profunda de la región.',
      difficulty: 'Fácil',
      estimatedTime: '1.5 horas',
      entryCost: '5 Bs.',
      bestSeason: 'Mayo – Noviembre',
      latitude: -17.9010,
      longitude: -64.4710,
    ),
    AdminPlace(
      name: 'Antiguo mirador norte',
      category: 'Mirador',
      mainCategory: 'Lugares',
      isActive: false,
      description: 'Antiguo punto de observación panorámica de la serranía de Siberia y del pueblo de Comarapa.',
      difficulty: 'Fácil',
      estimatedTime: '1 hora',
      entryCost: 'Gratuito',
      bestSeason: 'Todo el año',
      latitude: -17.9300,
      longitude: -64.4600,
    ),
    AdminPlace(
      name: 'Puerta al Amboró',
      category: 'Aventura',
      mainCategory: 'Lugares',
      isActive: true,
      description: 'Ingreso al majestuoso parque nacional Amboró, lleno de biodiversidad, helechos gigantes y paisajes de ensueño.',
      difficulty: 'Media',
      estimatedTime: 'Medio día',
      entryCost: '20 Bs.',
      bestSeason: 'Abril – Noviembre',
      latitude: -17.8950,
      longitude: -64.5100,
    ),
    AdminPlace(
      name: 'Mirador Serranía',
      category: 'Mirador',
      mainCategory: 'Lugares',
      isActive: true,
      description: 'Hermoso mirador natural en lo alto de la serranía, ideal para ver el amanecer y paisajes montañosos.',
      difficulty: 'Fácil',
      estimatedTime: '1 hora',
      entryCost: 'Gratuito',
      bestSeason: 'Todo el año',
      latitude: -17.9200,
      longitude: -64.4500,
    ),

    // Actividades
    AdminPlace(
      name: 'Senderismo Valle de los Cactus',
      category: 'Aventura',
      mainCategory: 'Actividades',
      isActive: true,
      description: 'Caminata guiada a través del sendero del Valle de los Cactus, aprendiendo sobre la flora del desierto.',
      difficulty: 'Fácil',
      estimatedTime: '2.5 horas',
      entryCost: '15 Bs.',
      bestSeason: 'Abril – Octubre',
      latitude: -17.9145,
      longitude: -64.4818,
    ),
    AdminPlace(
      name: 'Avistamiento de aves Siberia',
      category: 'Natural',
      mainCategory: 'Actividades',
      isActive: true,
      description: 'Observación guiada en el bosque nublado de la Siberia, hogar de especies endémicas espectaculares.',
      difficulty: 'Media',
      estimatedTime: '4 horas',
      entryCost: '30 Bs.',
      bestSeason: 'Octubre – Marzo',
      latitude: -17.8500,
      longitude: -64.4200,
    ),

    // Gastronomía
    AdminPlace(
      name: 'Pastelería La Tradición',
      category: 'Tradicional',
      mainCategory: 'Gastronomía',
      isActive: true,
      description: 'Famosa pastelería local donde podrás degustar empanadas tradicionales, horneados y licores artesanales.',
      difficulty: 'Fácil',
      estimatedTime: '1 hora',
      entryCost: 'Consumo',
      bestSeason: 'Todo el año',
      latitude: -17.9150,
      longitude: -64.4820,
    ),
    AdminPlace(
      name: 'Café Comarapa',
      category: 'Cafetería',
      mainCategory: 'Gastronomía',
      isActive: true,
      description: 'Café de especialidad cultivado en los valles templados, servido con repostería típica de Comarapa.',
      difficulty: 'Fácil',
      estimatedTime: '1 hora',
      entryCost: 'Consumo',
      bestSeason: 'Todo el año',
      latitude: -17.9130,
      longitude: -64.4830,
    ),

    // Hoteles
    AdminPlace(
      name: 'Hotel Plaza Comarapa',
      category: 'Hotel',
      mainCategory: 'Hoteles',
      isActive: true,
      description: 'Hotel confortable ubicado a media cuadra de la plaza principal, con estacionamiento y WiFi.',
      difficulty: 'Fácil',
      estimatedTime: 'Por noche',
      entryCost: '150 Bs.',
      bestSeason: 'Todo el año',
      latitude: -17.9140,
      longitude: -64.4810,
    ),
    AdminPlace(
      name: 'Hostal Las Orquídeas',
      category: 'Hostal',
      mainCategory: 'Hoteles',
      isActive: false,
      description: 'Hostal ecológico con hermosos jardines y atención familiar, ideal para viajeros aventureros.',
      difficulty: 'Fácil',
      estimatedTime: 'Por noche',
      entryCost: '80 Bs.',
      bestSeason: 'Todo el año',
      latitude: -17.9180,
      longitude: -64.4850,
    ),
  ];

  @override
  void initState() {
    super.initState();
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

  // Helper mapping names to custom painters defined in places_screen.dart
  CustomPainter _getPainterForPlace(AdminPlace place) {
    final name = place.name.toLowerCase();
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

  List<AdminPlace> get _filteredPlaces {
    return _places.where((place) {
      final matchesMainCategory = place.mainCategory == _selectedMainCategory;
      final matchesStatus = _selectedStatusFilter == 'Todos' ||
          (_selectedStatusFilter == 'Activos' && place.isActive) ||
          (_selectedStatusFilter == 'Inactivos' && !place.isActive);
      final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesMainCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  int _getCount(String status) {
    return _places.where((place) {
      final matchesMain = place.mainCategory == _selectedMainCategory;
      if (status == 'Todos') return matchesMain;
      if (status == 'Activos') return matchesMain && place.isActive;
      return matchesMain && !place.isActive;
    }).length;
  }

  void _toggleVisibility(AdminPlace place) {
    setState(() {
      place.isActive = !place.isActive;
    });
  }

  void _openPlaceDialog([AdminPlace? place]) {
    final nameController = TextEditingController(text: place?.name ?? '');
    String selectedCategory = place?.category ?? 'Natural';
    String selectedMainCategory = place?.mainCategory ?? _selectedMainCategory;
    bool isActive = place?.isActive ?? true;

    final categories = ['Natural', 'Arqueológico', 'Aventura', 'Mirador', 'Tradicional', 'Cafetería', 'Hotel', 'Hostal'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAF9F6),
              title: Text(
                place == null ? 'Nuevo lugar' : 'Editar lugar',
                style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: Color(0xFF0C3D28)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del lugar',
                        labelStyle: TextStyle(color: Color(0xFF1B5A3F)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1B5A3F))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMainCategory,
                      decoration: const InputDecoration(labelText: 'Categoría Principal'),
                      items: _mainCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedMainCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Sub-categoría / Tipo'),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Activo'),
                      activeThumbColor: const Color(0xFF1B5A3F),
                      value: isActive,
                      onChanged: (val) {
                        setDialogState(() {
                          isActive = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5A3F)),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    setState(() {
                      if (place == null) {
                        _places.add(AdminPlace(
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          mainCategory: selectedMainCategory,
                          isActive: isActive,
                        ));
                      } else {
                        place.name = nameController.text.trim();
                        place.category = selectedCategory;
                        place.mainCategory = selectedMainCategory;
                        place.isActive = isActive;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    final name = preferences.name.isEmpty ? 'Diplomante' : preferences.name;
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();

    final filteredList = _filteredPlaces;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF9F6),
      drawer: _buildDrawer(name, context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlaceDialog(),
        backgroundColor: const Color(0xFF2A7353),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Nuevo lugar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModeBanner(),
            _buildTopAppBar(initials),
            const SizedBox(height: 16),
            _buildMainCategoryTabs(),
            const SizedBox(height: 16),
            _buildSubFiltersRow(),
            if (_isSearching) _buildSearchInput(),
            const SizedBox(height: 12),
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final place = filteredList[index];
                        return _buildPlaceCard(place);
                      },
                    ),
            ),
            _buildNoticeBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(String initials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular menu button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF0C3D28),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PANEL ADMIN',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Lugares',
                    style: TextStyle(
                      color: Color(0xFF0C3D28),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      fontFamily: 'serif',
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User Initials Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE2ECE7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF1B5A3F),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryTabs() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _mainCategories.length,
        itemBuilder: (context, index) {
          final cat = _mainCategories[index];
          final isSelected = _selectedMainCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMainCategory = cat;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0C3D28) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0C3D28) : Colors.grey.shade200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubFiltersRow() {
    final filters = ['Todos', 'Activos', 'Inactivos'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: filters.map((filter) {
              final isSelected = _selectedStatusFilter == filter;
              final count = _getCount(filter);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatusFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A7353) : const Color(0xFFE5EFEA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$filter · $count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF2A7353),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Search Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(AdminPlace place) {
    final Color badgeBg = place.isActive ? const Color(0xFFE5EFEA) : const Color(0xFFEAEAEA);
    final Color badgeTextColor = place.isActive ? const Color(0xFF2A7353) : const Color(0xFF777777);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image Thumbnail or grey if inactive
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: place.isActive
                  ? CustomPaint(painter: _getPainterForPlace(place))
                  : Container(
                      color: Colors.grey.shade400,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 28),
                    ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: place.isActive ? const Color(0xFF1F2937) : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        place.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: place.isActive ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: badgeTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: place.isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () async {
                    final updatedPlace = await Navigator.push<AdminPlace>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPlaceScreen(place: place),
                      ),
                    );
                    if (updatedPlace != null) {
                      setState(() {
                        place.name = updatedPlace.name;
                        place.category = updatedPlace.category;
                        place.mainCategory = updatedPlace.mainCategory;
                        place.isActive = updatedPlace.isActive;
                        place.description = updatedPlace.description;
                        place.difficulty = updatedPlace.difficulty;
                        place.estimatedTime = updatedPlace.estimatedTime;
                        place.entryCost = updatedPlace.entryCost;
                        place.bestSeason = updatedPlace.bestSeason;
                        place.latitude = updatedPlace.latitude;
                        place.longitude = updatedPlace.longitude;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    place.isActive ? Icons.visibility : Icons.visibility_off,
                    color: place.isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () => _toggleVisibility(place),
                ),
              ],
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
            Icon(Icons.layers_clear_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No hay elementos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba cambiando el filtro de estado o agregando un nuevo elemento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF2A7353),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Desactivar un lugar lo oculta de la app (borrado lógico); se puede reactivar cuando quieras.',
              style: TextStyle(
                color: Color(0xFF2A7353),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String name, BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAF9F6),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0C3D28),
            ),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE2ECE7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Color(0xFF1B5A3F),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('Administrador de la Aplicación'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('1. Mis registros (BD)'),
                  subtitle: const Text('CRUD de la Sesión 1'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecordsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Color(0xFF1B5A3F)),
                  title: const Text('2. Conexión con el mundo'),
                  subtitle: const Text('GPS, clima y mapa'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContextLabScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune, color: Color(0xFF1B5A3F)),
                  title: const Text('3. Preferencias de usuario'),
                  subtitle: const Text('Persistencia local SharedPreferences'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.design_services_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('4. Adaptar a mi proyecto'),
                  subtitle: const Text('Acerca del proyecto'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutAdaptationScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Turismo Comarapa v1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
