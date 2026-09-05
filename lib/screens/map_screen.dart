import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/restaurante.dart';
import '../repositories/evento_repository.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lugar_repository.dart';
import '../repositories/restaurante_repository.dart';
import 'event_detail_screen.dart';
import 'hotel_detail_screen.dart';
import 'place_detail_screen.dart';
import 'restaurant_detail_screen.dart';

/// Tipo de entidad turística en el mapa
enum MapCategoryType { lugares, hoteles, restaurantes, eventos }

/// Abstracción uniforme para dibujar marcadores y la tarjeta inferior
class MapEntityItem {
  final String id;
  final String nombre;
  final String categoria;
  final String subtitulo;
  final double calificacion;
  final LatLng point;
  final List<String> imagenes;
  final MapCategoryType type;
  final dynamic rawData;

  const MapEntityItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.subtitulo,
    required this.calificacion,
    required this.point,
    required this.imagenes,
    required this.type,
    required this.rawData,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  MapCategoryType _selectedCategory = MapCategoryType.lugares;
  String _searchQuery = '';
  bool _loading = true;

  MapEntityItem? _selectedItem;

  // Listas de datos cargados
  List<Lugar> _lugares = [];
  List<Hotel> _hoteles = [];
  List<Restaurante> _restaurantes = [];
  List<Evento> _eventos = [];

  // Coordenadas centrales por defecto de Comarapa
  static const LatLng _comarapaCenter = LatLng(-18.0447, -64.5301);

  // Fallbacks curados de Comarapa con coordenadas representativas
  static final List<Lugar> _demoLugares = [
    Lugar(
      id: 'demo-lug-1',
      nombre: 'Valle de los Cactus',
      categoriaNombre: 'Natural',
      descripcion:
          'Mirador natural con decenas de especies de cactáceas gigantes en un entorno rocoso único.',
      latitud: -17.9144,
      longitud: -64.5319,
      dificultad: 'Fácil',
      tiempoVisitaMin: 120,
      activo: true,
      imagenes: const [],
    ),
    Lugar(
      id: 'demo-lug-2',
      nombre: 'Laguna Verde',
      categoriaNombre: 'Aventura',
      descripcion: 'Hermoso espejo de agua enclavado entre montañas y senderos vallunos.',
      latitud: -18.0650,
      longitud: -64.5450,
      dificultad: 'Moderado',
      tiempoVisitaMin: 180,
      activo: true,
      imagenes: const [],
    ),
    Lugar(
      id: 'demo-lug-3',
      nombre: 'Represa La Cañada',
      categoriaNombre: 'Paisaje',
      descripcion: 'Impresionante represa rodeada de vegetación y fauna comarapeña.',
      latitud: -18.0120,
      longitud: -64.5100,
      dificultad: 'Fácil',
      tiempoVisitaMin: 90,
      activo: true,
      imagenes: const [],
    ),
    Lugar(
      id: 'demo-lug-4',
      nombre: 'Mirador de la Cruz',
      categoriaNombre: 'Mirador',
      descripcion: 'Punto panorámico sobre toda la ciudad colonial de Comarapa.',
      latitud: -18.0410,
      longitud: -64.5320,
      dificultad: 'Fácil',
      tiempoVisitaMin: 45,
      activo: true,
      imagenes: const [],
    ),
    Lugar(
      id: 'demo-lug-5',
      nombre: 'Jardín de las Cactáceas',
      categoriaNombre: 'Ecológico',
      descripcion: 'Sendero botánico interpretativo con especies endémicas de los valles.',
      latitud: -17.9300,
      longitud: -64.5250,
      dificultad: 'Fácil',
      tiempoVisitaMin: 60,
      activo: true,
      imagenes: const [],
    ),
  ];

  static final List<Hotel> _demoHoteles = [
    const Hotel(
      id: 'demo-hotel-1',
      nombre: 'Hotel Valle Verde',
      categoriaNombre: 'Hotel',
      descripcion: 'Alojamiento confortable en el centro de Comarapa con agua caliente y wifi.',
      precioMin: 180,
      precioMax: 250,
      direccionReferencia: 'Av. Circunvalación',
      contactoReservas: '+591 3 936 1145',
      latitud: -18.0401,
      longitud: -64.5276,
      calificacionPromedio: 4.8,
      activo: true,
      imagenes: [],
    ),
    const Hotel(
      id: 'demo-hotel-2',
      nombre: 'Hostal El Mirador del Valle',
      categoriaNombre: 'Hostal',
      descripcion: 'Acogedor hostal familiar con terraza y vistas panorámicas a los huertos.',
      precioMin: 90,
      precioMax: 140,
      direccionReferencia: 'Calle Sucre esq. Bolívar',
      contactoReservas: '+591 712 34567',
      latitud: -18.0375,
      longitud: -64.5290,
      calificacionPromedio: 4.6,
      activo: true,
      imagenes: [],
    ),
    const Hotel(
      id: 'demo-hotel-3',
      nombre: 'Cabañas Rústicas La Pajcha',
      categoriaNombre: 'Cabaña',
      descripcion: 'Cabañas de piedra y madera en entorno campestre con fogata nocturna.',
      precioMin: 220,
      precioMax: 350,
      direccionReferencia: 'Camino a La Pajcha km 4',
      contactoReservas: '+591 721 98765',
      latitud: -18.0280,
      longitud: -64.5150,
      calificacionPromedio: 4.9,
      activo: true,
      imagenes: [],
    ),
    const Hotel(
      id: 'demo-hotel-4',
      nombre: 'Camping Ecológico Los Sauces',
      categoriaNombre: 'Camping',
      descripcion: 'Espacio verde a orillas del río para acampar bajo las estrellas.',
      precioMin: 40,
      precioMax: 70,
      direccionReferencia: 'Sector Los Sauces',
      contactoReservas: '+591 730 45678',
      latitud: -18.0510,
      longitud: -64.5320,
      calificacionPromedio: 4.5,
      activo: true,
      imagenes: [],
    ),
    const Hotel(
      id: 'demo-hotel-5',
      nombre: 'Residencial Comarapa Colonial',
      categoriaNombre: 'Hostal',
      descripcion: 'Casona tradicional restaurada con patio central lleno de plantas.',
      precioMin: 110,
      precioMax: 160,
      direccionReferencia: 'Calle 16 de Julio #45',
      contactoReservas: '+591 3 936 1020',
      latitud: -18.0392,
      longitud: -64.5265,
      calificacionPromedio: 4.7,
      activo: true,
      imagenes: [],
    ),
  ];

  static final List<Restaurante> _demoRestaurantes = [
    const Restaurante(
      id: 'demo-rest-1',
      nombre: 'El Fogón Comarapeño',
      categoriaNombre: 'Comida típica',
      descripcion: 'Picante de pollo criollo con duraznos caramelizados y sopa de maní.',
      direccionReferencia: 'Calle Sucre esq. Bolívar',
      horarioAtencion: '11:30 - 21:30',
      precioReferencial: 45,
      calificacionPromedio: 4.8,
      latitud: -18.0388,
      longitud: -64.5283,
      activo: true,
      imagenes: [],
    ),
    const Restaurante(
      id: 'demo-rest-2',
      nombre: 'La Terraza del Durazno',
      categoriaNombre: 'Café & repostería',
      descripcion: 'Cafetería con terraza, empanadas blanqueadas y jugos de fruta natural.',
      direccionReferencia: 'Av. Circunvalación #85',
      horarioAtencion: '08:00 - 20:00',
      precioReferencial: 25,
      calificacionPromedio: 4.6,
      latitud: -18.0410,
      longitud: -64.5260,
      activo: true,
      imagenes: [],
    ),
    const Restaurante(
      id: 'demo-rest-3',
      nombre: 'Parrilla El Chaqueño',
      categoriaNombre: 'Parrilla',
      descripcion: 'Carnes a la brasa de quebracho blanco, costillitas y pacumutos.',
      direccionReferencia: 'Carretera Antigua a Cochabamba km 2',
      horarioAtencion: '12:00 - 22:30',
      precioReferencial: 55,
      calificacionPromedio: 4.7,
      latitud: -18.0460,
      longitud: -64.5320,
      activo: true,
      imagenes: [],
    ),
    const Restaurante(
      id: 'demo-rest-4',
      nombre: 'Pizzería Don Beto',
      categoriaNombre: 'Pizzería',
      descripcion: 'Pizzas horneadas a la piedra con queso criollo de los valles.',
      direccionReferencia: 'Calle 16 de Julio',
      horarioAtencion: '17:30 - 23:00',
      precioReferencial: 40,
      calificacionPromedio: 4.4,
      latitud: -18.0425,
      longitud: -64.5295,
      activo: true,
      imagenes: [],
    ),
    const Restaurante(
      id: 'demo-rest-5',
      nombre: 'Rincón Camba Valluno',
      categoriaNombre: 'Comida oriental',
      descripcion: 'Majadito de pato tostado, pacumutos de res y refresco de somó frío.',
      direccionReferencia: 'Barrio San José',
      horarioAtencion: '11:00 - 16:00',
      precioReferencial: 35,
      calificacionPromedio: 4.5,
      latitud: -18.0370,
      longitud: -64.5240,
      activo: true,
      imagenes: [],
    ),
  ];

  static final List<Evento> _demoEventos = [
    Evento(
      id: 'demo-ev-1',
      nombre: 'Feria Nacional del Durazno',
      categoriaNombre: 'Feria',
      descripcion:
          'Festividad productiva de Comarapa con exhibición de duraznos y música en vivo.',
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
          'Misa campal, procesión solemne por calles coloniales y comparsas de danzarines.',
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
      nombre: 'Festival del Maíz y la Tradición',
      categoriaNombre: 'Festival',
      descripcion: 'Muestra gastronómica de humintas, tamales y coplas vallunas tradicionales.',
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
      descripcion: 'Senderismo guiado, avistamiento de aves y fogatas campestres.',
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
      descripcion: 'Desfile cívico institucional, sesión de honor y serenata folclórica.',
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
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);

    try {
      final lugares = await context.read<LugarRepository>().fetchActivos();
      final hoteles = await context.read<HotelRepository>().fetchActivos();
      final restaurantes = await context.read<RestauranteRepository>().fetchActivos();
      final eventos = await context.read<EventoRepository>().fetchActivos();

      if (!mounted) return;
      setState(() {
        _lugares = lugares.isNotEmpty ? lugares : _demoLugares;
        _hoteles = hoteles.isNotEmpty ? hoteles : _demoHoteles;
        _restaurantes = restaurantes.isNotEmpty ? restaurantes : _demoRestaurantes;
        _eventos = eventos.isNotEmpty ? eventos : _demoEventos;
        _loading = false;
        _updateSelectedItemForCategory();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lugares = _demoLugares;
        _hoteles = _demoHoteles;
        _restaurantes = _demoRestaurantes;
        _eventos = _demoEventos;
        _loading = false;
        _updateSelectedItemForCategory();
      });
    }
  }

  void _updateSelectedItemForCategory() {
    final items = _currentCategoryItems;
    if (items.isNotEmpty) {
      _selectedItem = items.first;
      // Centrar suavemente en el primer punto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedItem != null) {
          _mapController.move(_selectedItem!.point, 13.5);
        }
      });
    } else {
      _selectedItem = null;
    }
  }

  List<MapEntityItem> get _allCategoryItems {
    switch (_selectedCategory) {
      case MapCategoryType.lugares:
        return _lugares.map((l) {
          final lat = (l.latitud != null && l.latitud != 0) ? l.latitud! : _comarapaCenter.latitude;
          final lng = (l.longitud != null && l.longitud != 0) ? l.longitud! : _comarapaCenter.longitude;
          final dif = l.dificultad.isNotEmpty ? l.dificultad : 'Fácil';
          final sub = '${l.categoriaNombre ?? "Natural"} · a 12 km · $dif';
          return MapEntityItem(
            id: l.id ?? l.nombre,
            nombre: l.nombre,
            categoria: l.categoriaNombre ?? 'Natural',
            subtitulo: sub,
            calificacion: 4.2,
            point: LatLng(lat, lng),
            imagenes: l.imagenes,
            type: MapCategoryType.lugares,
            rawData: l,
          );
        }).toList();

      case MapCategoryType.hoteles:
        return _hoteles.map((h) {
          final lat = (h.latitud != null && h.latitud != 0) ? h.latitud! : _comarapaCenter.latitude;
          final lng = (h.longitud != null && h.longitud != 0) ? h.longitud! : _comarapaCenter.longitude;
          final precio = h.precioMin != null ? 'Desde Bs ${h.precioMin!.toInt()}' : 'Bs 150 - 250';
          final sub = '${h.categoriaNombre ?? "Hotel"} · $precio · Comarapa';
          return MapEntityItem(
            id: h.id ?? h.nombre,
            nombre: h.nombre,
            categoria: h.categoriaNombre ?? 'Hotel',
            subtitulo: sub,
            calificacion: h.calificacionPromedio > 0 ? h.calificacionPromedio.toDouble() : 4.8,
            point: LatLng(lat, lng),
            imagenes: h.imagenes,
            type: MapCategoryType.hoteles,
            rawData: h,
          );
        }).toList();

      case MapCategoryType.restaurantes:
        return _restaurantes.map((r) {
          final lat = (r.latitud != null && r.latitud != 0) ? r.latitud! : _comarapaCenter.latitude;
          final lng = (r.longitud != null && r.longitud != 0) ? r.longitud! : _comarapaCenter.longitude;
          final horario = (r.horarioAtencion?.isNotEmpty == true) ? r.horarioAtencion! : '11:30 - 21:30';
          final sub = '${r.categoriaNombre ?? "Restaurante"} · $horario';
          return MapEntityItem(
            id: r.id ?? r.nombre,
            nombre: r.nombre,
            categoria: r.categoriaNombre ?? 'Restaurante',
            subtitulo: sub,
            calificacion: r.calificacionPromedio > 0 ? r.calificacionPromedio.toDouble() : 4.7,
            point: LatLng(lat, lng),
            imagenes: r.imagenes,
            type: MapCategoryType.restaurantes,
            rawData: r,
          );
        }).toList();

      case MapCategoryType.eventos:
        return _eventos.map((e) {
          final lat = (e.latitud != null && e.latitud != 0) ? e.latitud! : _comarapaCenter.latitude;
          final lng = (e.longitud != null && e.longitud != 0) ? e.longitud! : _comarapaCenter.longitude;
          final per = e.periodicidad?.isNotEmpty == true ? e.periodicidad! : 'Anual';
          final sub = '${e.categoriaNombre ?? "Festividad"} · $per · Comarapa';
          return MapEntityItem(
            id: e.id ?? e.nombre,
            nombre: e.nombre,
            categoria: e.categoriaNombre ?? 'Evento',
            subtitulo: sub,
            calificacion: 4.9,
            point: LatLng(lat, lng),
            imagenes: e.imagenes,
            type: MapCategoryType.eventos,
            rawData: e,
          );
        }).toList();
    }
  }

  List<MapEntityItem> get _currentCategoryItems {
    final all = _allCategoryItems;
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((item) {
      return item.nombre.toLowerCase().contains(query) ||
          item.categoria.toLowerCase().contains(query) ||
          item.subtitulo.toLowerCase().contains(query);
    }).toList();
  }

  Color get _categoryColor {
    switch (_selectedCategory) {
      case MapCategoryType.lugares:
        return const Color(0xFF1B5A3F); // Verde bosque Comarapa
      case MapCategoryType.hoteles:
        return const Color(0xFF1E3A8A); // Azul añil
      case MapCategoryType.restaurantes:
        return const Color(0xFFC68B59); // Terracota cálido
      case MapCategoryType.eventos:
        return const Color(0xFFB45309); // Ámbar festivo
    }
  }

  void _onSelectCategory(MapCategoryType type) {
    if (_selectedCategory == type) return;
    setState(() {
      _selectedCategory = type;
      _updateSelectedItemForCategory();
    });
  }

  void _onTapMarker(MapEntityItem item) {
    setState(() {
      _selectedItem = item;
    });
    _mapController.move(item.point, _mapController.camera.zoom);
  }

  void _recenterMap() {
    if (_selectedItem != null) {
      _mapController.move(_selectedItem!.point, 14.0);
    } else {
      _mapController.move(_comarapaCenter, 13.5);
    }
  }

  void _openDetailScreen(MapEntityItem item) {
    Widget destination;
    switch (item.type) {
      case MapCategoryType.lugares:
        destination = PlaceDetailScreen(lugar: item.rawData as Lugar);
        break;
      case MapCategoryType.hoteles:
        destination = HotelDetailScreen(hotel: item.rawData as Hotel);
        break;
      case MapCategoryType.restaurantes:
        destination = RestaurantDetailScreen(restaurante: item.rawData as Restaurante);
        break;
      case MapCategoryType.eventos:
        destination = EventDetailScreen(evento: item.rawData as Evento);
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentCategoryItems;

    return Stack(
      children: [
        // 1. MAPA DE FONDO COMPLETO
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _comarapaCenter,
            initialZoom: 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
            ),
            MarkerLayer(
              markers: items.map((item) {
                final isSelected = _selectedItem?.id == item.id;
                return Marker(
                  point: item.point,
                  width: isSelected ? 46 : 38,
                  height: isSelected ? 46 : 38,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _onTapMarker(item),
                    child: _buildMapPin(item, isSelected),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // 2. CAPA SUPERIOR: BUSCADOR Y CHIPS DE CATEGORÍAS FLOTANTES
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _buildTopSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
            ],
          ),
        ),

        // 3. BOTÓN FLOTANTE GPS / RECENTRAR
        Positioned(
          right: 20,
          bottom: 124,
          child: GestureDetector(
            onTap: _recenterMap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF1B5A3F),
                size: 22,
              ),
            ),
          ),
        ),

        // 4. TARJETA FLOTANTE DE PREVISUALIZACIÓN INFERIOR
        if (_selectedItem != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomPreviewCard(_selectedItem!),
          ),

        // Indicador de carga inicial discreto
        if (_loading)
          const Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1B5A3F),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar en el mapa...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14.5,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 22,
            ),
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

  Widget _buildCategoryChips() {
    const categories = [
      {'type': MapCategoryType.lugares, 'label': 'Lugares'},
      {'type': MapCategoryType.hoteles, 'label': 'Hoteles'},
      {'type': MapCategoryType.restaurantes, 'label': 'Restaurantes'},
      {'type': MapCategoryType.eventos, 'label': 'Eventos'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final type = cat['type'] as MapCategoryType;
          final label = cat['label'] as String;
          final isSelected = _selectedCategory == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onSelectCategory(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B5A3F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1B5A3F) : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPin(MapEntityItem item, bool isSelected) {
    Color pinColor;
    switch (item.type) {
      case MapCategoryType.lugares:
        pinColor = const Color(0xFF26674B);
        break;
      case MapCategoryType.hoteles:
        pinColor = const Color(0xFF1E3A8A);
        break;
      case MapCategoryType.restaurantes:
        pinColor = const Color(0xFFC68B59);
        break;
      case MapCategoryType.eventos:
        pinColor = const Color(0xFFB45309);
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Sombra suave bajo el pin
        Positioned(
          bottom: 2,
          child: Container(
            width: isSelected ? 18 : 14,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Pin personalizado en forma de gota con punto blanco
        CustomPaint(
          size: Size(isSelected ? 42 : 34, isSelected ? 42 : 34),
          painter: TeardropPinPainter(
            color: pinColor,
            isSelected: isSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPreviewCard(MapEntityItem item) {
    return GestureDetector(
      onTap: () => _openDetailScreen(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Miniatura izquierda (cuadrado 68x68 redondeado)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _categoryColor.withValues(alpha: 0.12),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imagenes.isNotEmpty
                  ? Image.network(
                      item.imagenes.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackThumbnail(item),
                    )
                  : _buildFallbackThumbnail(item),
            ),
            const SizedBox(width: 14),

            // Contenido informativo central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título principal
                  Text(
                    item.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF143525),
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtítulo descriptivo
                  Text(
                    item.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Calificación
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFE59819),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.calificacion.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Flecha indicadora derecha
            const Padding(
              padding: EdgeInsets.only(left: 8, right: 4),
              child: Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail(MapEntityItem item) {
    IconData icon;
    switch (item.type) {
      case MapCategoryType.lugares:
        icon = Icons.landscape;
        break;
      case MapCategoryType.hoteles:
        icon = Icons.hotel;
        break;
      case MapCategoryType.restaurantes:
        icon = Icons.restaurant;
        break;
      case MapCategoryType.eventos:
        icon = Icons.celebration;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _categoryColor,
            _categoryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/// Custom painter que reproduce exactamente los pines de ubicación en forma de gota
/// con un círculo blanco interior como en la captura del usuario.
class TeardropPinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  TeardropPinPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final r = size.width * 0.42;

    // Cuerpo del pin en gota
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Resaltado para el pin seleccionado
    if (isSelected) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final glowPath = Path()
        ..moveTo(cx, size.height)
        ..quadraticBezierTo(cx - r - 2, size.height * 0.55, cx - r - 2, r + 2)
        ..arcToPoint(
          Offset(cx + r + 2, r + 2),
          radius: Radius.circular(r + 2),
          clockwise: true,
        )
        ..quadraticBezierTo(cx + r + 2, size.height * 0.55, cx, size.height)
        ..close();
      canvas.drawPath(glowPath, glowPaint);
    }

    final pinPath = Path()
      ..moveTo(cx, size.height)
      ..quadraticBezierTo(cx - r, size.height * 0.55, cx - r, r)
      ..arcToPoint(
        Offset(cx + r, r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(cx + r, size.height * 0.55, cx, size.height)
      ..close();

    canvas.drawPath(pinPath, pinPaint);

    // Punto blanco central
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, r), r * 0.44, dotPaint);

    // Mini detalle de sombra interna
    final innerDot = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(cx, r), r * 0.22, innerDot);
  }

  @override
  bool shouldRepaint(covariant TeardropPinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSelected != isSelected;
  }
}
