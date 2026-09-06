import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/actividad.dart';
import '../models/evento.dart';
import '../models/gastronomia_item.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/restaurante.dart';
import '../models/turismo_tipo.dart';
import '../models/usuario_perfil.dart';
import '../repositories/actividad_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lugar_repository.dart';
import '../repositories/restaurante_repository.dart';
import '../repositories/usuario_repository.dart';
import '../widgets/mode_banner.dart';
import 'about_adaptation_screen.dart';
import 'admin_users_screen.dart';
import 'context/context_lab_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'places_screen.dart';
import 'edit_place_screen.dart';
import 'edit_hotel_screen.dart';
import 'new_hotel_screen.dart';
import 'edit_event_screen.dart';
import 'new_event_screen.dart';
import 'edit_restaurant_screen.dart';
import 'new_restaurant_screen.dart';

class _CardData {
  const _CardData({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.activo,
    this.precioInfo,
    this.calificacion,
    this.thumbnailColor,
    this.fechaBadgeDay,
    this.fechaBadgeMonth,
    this.periodicidad,
    this.badgeBgColor,
    this.badgeTextColor,
    this.imagenes = const <String>[],
  });

  final String id;
  final String nombre;
  final String categoria;
  final bool activo;
  final String? precioInfo;
  final num? calificacion;
  final Color? thumbnailColor;
  final String? fechaBadgeDay;
  final String? fechaBadgeMonth;
  final String? periodicidad;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final List<String> imagenes;
}

class AdminHomeScreen extends StatefulWidget {
  final TurismoTipo initialTipo;

  const AdminHomeScreen({
    super.key,
    this.initialTipo = TurismoTipo.lugar,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  static final List<Hotel> _demoHoteles = [
    const Hotel(
      id: 'demo-hotel-1',
      nombre: 'Hotel Valle Verde',
      categoriaNombre: 'Hotel',
      precioMin: 180,
      precioMax: 250,
      calificacionPromedio: 4.5,
      activo: true,
    ),
    const Hotel(
      id: 'demo-hotel-2',
      nombre: 'Cabañas El Durazno',
      categoriaNombre: 'Cabaña',
      precioMin: 220,
      precioMax: 320,
      calificacionPromedio: 4.8,
      activo: true,
    ),
    const Hotel(
      id: 'demo-hotel-3',
      nombre: 'Hostal Serranía',
      categoriaNombre: 'Hostal',
      precioMin: 90,
      precioMax: 140,
      calificacionPromedio: 4.1,
      activo: true,
    ),
    const Hotel(
      id: 'demo-hotel-4',
      nombre: 'Camping Ambóró',
      categoriaNombre: 'Camping',
      precioMin: 60,
      precioMax: 90,
      calificacionPromedio: 4.2,
      activo: false,
    ),
  ];

  static final List<Evento> _demoEventos = [
    Evento(
      id: 'demo-evento-1',
      nombre: 'Feria del Durazno',
      categoriaNombre: 'Feria',
      fechaInicio: DateTime(2026, 1, 15),
      periodicidad: 'anual',
      activo: true,
    ),
    Evento(
      id: 'demo-evento-2',
      nombre: 'Fiesta patronal de Comarapa',
      categoriaNombre: 'Fiesta patronal',
      fechaInicio: DateTime(2026, 9, 14),
      periodicidad: 'anual',
      activo: true,
    ),
    Evento(
      id: 'demo-evento-3',
      nombre: 'Feria agropecuaria',
      categoriaNombre: 'Feria',
      fechaInicio: DateTime(2026, 10, 2),
      periodicidad: 'anual',
      activo: true,
    ),
    Evento(
      id: 'demo-evento-4',
      nombre: 'Encuentro de agroturismo',
      categoriaNombre: 'Cultural',
      fechaInicio: DateTime(2026, 11, 21),
      periodicidad: 'único',
      activo: false,
    ),
  ];

  static final List<Restaurante> _demoRestaurantes = [
    const Restaurante(
      id: 'demo-restaurante-1',
      nombre: 'El Fogón Comarapeño',
      categoriaNombre: 'Comida típica',
      calificacionPromedio: 4.8,
      activo: true,
    ),
    const Restaurante(
      id: 'demo-restaurante-2',
      nombre: 'La Terraza del Durazno',
      categoriaNombre: 'Café & repostería',
      calificacionPromedio: 4.6,
      activo: true,
    ),
    const Restaurante(
      id: 'demo-restaurante-3',
      nombre: 'Rincón Camba',
      categoriaNombre: 'Comida oriental',
      calificacionPromedio: 4.5,
      activo: true,
    ),
    const Restaurante(
      id: 'demo-restaurante-4',
      nombre: 'Pizzería Don Beto',
      categoriaNombre: 'Pizzería',
      calificacionPromedio: 4.0,
      activo: false,
    ),
  ];

  TurismoTipo _selectedTipo = TurismoTipo.lugar;
  String _selectedStatusFilter = 'Todos';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _loading = true;
  String? _error;
  UsuarioPerfil? _perfil;

  List<Lugar> _lugares = <Lugar>[];
  List<Actividad> _actividades = <Actividad>[];
  List<Hotel> _hoteles = <Hotel>[];
  List<Evento> _eventos = <Evento>[];
  List<Restaurante> _restaurantes = <Restaurante>[];
  List<GastronomiaItem> _gastronomia = <GastronomiaItem>[];

  @override
  void initState() {
    super.initState();
    _selectedTipo = widget.initialTipo;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadAll();
    _loadPerfil();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPerfil() async {
    try {
      final perfil = await context.read<UsuarioRepository>().fetchCurrent();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Informativo: si falla, el panel sigue funcionando igual.
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lugares = await context.read<LugarRepository>().fetchAll();
      final actividades = await context.read<ActividadRepository>().fetchAll();
      final hoteles = await context.read<HotelRepository>().fetchAll();
      final gastronomia = await context.read<GastronomiaRepository>().fetchAll();
      List<Evento> eventos = [];
      try {
        eventos = await context.read<EventoRepository>().fetchAll();
      } catch (_) {
        // En caso de que la tabla aún esté vacía o sin migrar
      }
      List<Restaurante> restaurantes = [];
      try {
        restaurantes = await context.read<RestauranteRepository>().fetchAll();
      } catch (_) {
        // En caso de que la tabla aún esté vacía o sin migrar
      }

      if (!mounted) return;
      setState(() {
        _lugares = lugares;
        _actividades = actividades;
        _hoteles = hoteles;
        _eventos = eventos;
        _restaurantes = restaurantes;
        _gastronomia = gastronomia;
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

  CustomPainter _getPainterForNombre(String nombre) {
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

  Color _getColorForHotel(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('verde') || n.contains('valle')) {
      return const Color(0xFF488463);
    } else if (n.contains('durazno') || n.contains('cabaña') || n.contains('cabana')) {
      return const Color(0xFF8D653E);
    } else if (n.contains('serran') || n.contains('hostal')) {
      return const Color(0xFF5A9374);
    } else if (n.contains('ambor') || n.contains('camping')) {
      return const Color(0xFFB0B5B0);
    }
    return const Color(0xFF488463);
  }

  Color _getColorForRestaurante(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('fogón') || n.contains('fogon')) {
      return const Color(0xFFB57834);
    } else if (n.contains('terraza') || n.contains('durazno')) {
      return const Color(0xFF9E652E);
    } else if (n.contains('rincón') || n.contains('rincon') || n.contains('camba')) {
      return const Color(0xFF8A4633);
    } else if (n.contains('pizzer') || n.contains('beto')) {
      return const Color(0xFFA5ADA8);
    }
    return const Color(0xFFB57834);
  }

  List<_CardData> get _allCardData {
    switch (_selectedTipo) {
      case TurismoTipo.lugar:
        return _lugares
            .map((e) => _CardData(
                  id: e.id!,
                  nombre: e.nombre,
                  categoria: e.categoriaNombre ?? 'Sin categoría',
                  activo: e.activo,
                  imagenes: e.imagenes,
                ))
            .toList();
      case TurismoTipo.actividad:
        return _actividades
            .map((e) => _CardData(
                  id: e.id!,
                  nombre: e.nombre,
                  categoria: e.categoriaNombre ?? 'Sin categoría',
                  activo: e.activo,
                ))
            .toList();
      case TurismoTipo.hotel:
        final list = _hoteles.isNotEmpty ? _hoteles : _demoHoteles;
        return list.map((e) {
          String? precio;
          if (e.precioMin != null && e.precioMax != null) {
            precio = 'Bs ${e.precioMin?.toInt() ?? e.precioMin}–${e.precioMax?.toInt() ?? e.precioMax}';
          } else if (e.precioMin != null) {
            precio = 'Desde Bs ${e.precioMin}';
          }
          return _CardData(
            id: e.id ?? '',
            nombre: e.nombre,
            categoria: e.categoriaNombre ?? 'Hotel',
            activo: e.activo,
            precioInfo: precio,
            calificacion: e.calificacionPromedio > 0 ? e.calificacionPromedio : null,
            thumbnailColor: _getColorForHotel(e.nombre),
            imagenes: e.imagenes,
          );
        }).toList();
      case TurismoTipo.gastronomia:
        return _gastronomia
            .map((e) => _CardData(
                  id: e.id!,
                  nombre: e.nombre,
                  categoria: e.categoriaNombre ?? 'Sin categoría',
                  activo: e.activo,
                ))
            .toList();
      case TurismoTipo.evento:
        final list = _eventos.isNotEmpty ? _eventos : _demoEventos;
        return list.map((e) {
          return _CardData(
            id: e.id ?? '',
            nombre: e.nombre,
            categoria: e.categoriaNombre ?? 'Feria',
            activo: e.activo,
            fechaBadgeDay: e.diaFormateado,
            fechaBadgeMonth: e.mesAbreviado,
            periodicidad: e.periodicidad ?? 'anual',
            badgeBgColor: e.badgeBgColor,
            badgeTextColor: e.badgeTextColor,
            imagenes: e.imagenes,
          );
        }).toList();
      case TurismoTipo.restaurante:
        final list = _restaurantes.isNotEmpty ? _restaurantes : _demoRestaurantes;
        return list.map((e) {
          return _CardData(
            id: e.id ?? '',
            nombre: e.nombre,
            categoria: e.categoriaNombre ?? 'Restaurante',
            activo: e.activo,
            calificacion: e.calificacionPromedio > 0 ? e.calificacionPromedio : null,
            thumbnailColor: _getColorForRestaurante(e.nombre),
            imagenes: e.imagenes,
          );
        }).toList();
    }
  }

  List<_CardData> get _filteredCardData {
    return _allCardData.where((card) {
      final matchesStatus = _selectedStatusFilter == 'Todos' ||
          (_selectedStatusFilter == 'Activos' && card.activo) ||
          (_selectedStatusFilter == 'Inactivos' && !card.activo);
      final query = _searchQuery.toLowerCase();
      final matchesSearch = card.nombre.toLowerCase().contains(query) ||
          card.categoria.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  int _getCount(String status) {
    final all = _allCardData;
    if (status == 'Todos') return all.length;
    if (status == 'Activos') return all.where((c) => c.activo).length;
    return all.where((c) => !c.activo).length;
  }

  Future<void> _toggleVisibility(_CardData card) async {
    try {
      switch (_selectedTipo) {
        case TurismoTipo.lugar:
          await context.read<LugarRepository>().setActivo(card.id, !card.activo);
          break;
        case TurismoTipo.actividad:
          await context.read<ActividadRepository>().setActivo(card.id, !card.activo);
          break;
        case TurismoTipo.hotel:
          if (card.id.startsWith('demo-')) {
            final idx = _demoHoteles.indexWhere((h) => h.id == card.id);
            if (idx != -1) {
              setState(() {
                _demoHoteles[idx] = _demoHoteles[idx].copyWith(activo: !card.activo);
              });
              return;
            }
          }
          await context.read<HotelRepository>().setActivo(card.id, !card.activo);
          break;
        case TurismoTipo.gastronomia:
          await context.read<GastronomiaRepository>().setActivo(card.id, !card.activo);
          break;
        case TurismoTipo.evento:
          if (card.id.startsWith('demo-')) {
            final idx = _demoEventos.indexWhere((ev) => ev.id == card.id);
            if (idx != -1) {
              setState(() {
                _demoEventos[idx] = _demoEventos[idx].copyWith(activo: !card.activo);
              });
              return;
            }
          }
          await context.read<EventoRepository>().setActivo(card.id, !card.activo);
          break;
        case TurismoTipo.restaurante:
          if (card.id.startsWith('demo-')) {
            final idx = _demoRestaurantes.indexWhere((r) => r.id == card.id);
            if (idx != -1) {
              setState(() {
                _demoRestaurantes[idx] = _demoRestaurantes[idx].copyWith(activo: !card.activo);
              });
              return;
            }
          }
          await context.read<RestauranteRepository>().setActivo(card.id, !card.activo);
          break;
      }
      await _loadAll();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    }
  }

  Future<void> _openEditor([_CardData? card]) async {
    Widget screen;
    switch (_selectedTipo) {
      case TurismoTipo.lugar:
        final lugar = card == null ? null : _lugares.firstWhere((e) => e.id == card.id);
        screen = EditPlaceScreen(tipo: _selectedTipo, lugar: lugar);
        break;
      case TurismoTipo.actividad:
        final actividad = card == null ? null : _actividades.firstWhere((e) => e.id == card.id);
        screen = EditPlaceScreen(tipo: _selectedTipo, actividad: actividad);
        break;
      case TurismoTipo.hotel:
        if (card == null) {
          final newHotel = await Navigator.push<Hotel>(
            context,
            MaterialPageRoute(builder: (context) => const NewHotelScreen()),
          );
          if (newHotel != null) {
            setState(() {
              _demoHoteles.insert(0, newHotel);
            });
            await _loadAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hotel "${newHotel.nombre}" creado con éxito.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          return;
        }
        final allHoteles = _hoteles.isNotEmpty ? _hoteles : _demoHoteles;
        final hotel = allHoteles.firstWhere((e) => e.id == card.id, orElse: () => allHoteles.first);
        final updatedHotel = await Navigator.push<Hotel>(
          context,
          MaterialPageRoute(builder: (context) => EditHotelScreen(hotel: hotel)),
        );
        if (updatedHotel != null) {
          if (updatedHotel.id != null &&
              (updatedHotel.id!.startsWith('demo-') || updatedHotel.id!.startsWith('hotel-'))) {
            final idx = _demoHoteles.indexWhere((h) => h.id == updatedHotel.id);
            if (idx != -1) {
              setState(() => _demoHoteles[idx] = updatedHotel);
            }
          } else {
            await _loadAll();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hotel "${updatedHotel.nombre}" guardado con éxito.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      case TurismoTipo.gastronomia:
        final item = card == null ? null : _gastronomia.firstWhere((e) => e.id == card.id);
        screen = EditPlaceScreen(tipo: _selectedTipo, gastronomia: item);
        break;
      case TurismoTipo.evento:
        if (card == null) {
          final newEvento = await Navigator.push<Evento>(
            context,
            MaterialPageRoute(builder: (context) => const NewEventScreen()),
          );
          if (newEvento != null) {
            setState(() {
              _demoEventos.insert(0, newEvento);
            });
            await _loadAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Evento "${newEvento.nombre}" creado con éxito.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          return;
        }
        final allEventos = _eventos.isNotEmpty ? _eventos : _demoEventos;
        final evento = allEventos.firstWhere((e) => e.id == card.id, orElse: () => allEventos.first);
        final updatedEvento = await Navigator.push<Evento>(
          context,
          MaterialPageRoute(builder: (context) => EditEventScreen(evento: evento)),
        );
        if (updatedEvento != null) {
          if (updatedEvento.id != null &&
              (updatedEvento.id!.startsWith('demo-') || updatedEvento.id!.startsWith('evento-'))) {
            final idx = _demoEventos.indexWhere((ev) => ev.id == updatedEvento.id);
            if (idx != -1) {
              setState(() => _demoEventos[idx] = updatedEvento);
            }
          } else {
            await _loadAll();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Evento "${updatedEvento.nombre}" guardado con éxito.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      case TurismoTipo.restaurante:
        if (card == null) {
          final newRestaurante = await Navigator.push<Restaurante>(
            context,
            MaterialPageRoute(builder: (context) => const NewRestaurantScreen()),
          );
          if (newRestaurante != null) {
            setState(() {
              _demoRestaurantes.insert(0, newRestaurante);
            });
            await _loadAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Restaurante "${newRestaurante.nombre}" creado con éxito.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          return;
        }
        final allRestaurantes = _restaurantes.isNotEmpty ? _restaurantes : _demoRestaurantes;
        final restaurante = allRestaurantes.firstWhere((e) => e.id == card.id, orElse: () => allRestaurantes.first);
        final updatedRestaurante = await Navigator.push<Restaurante>(
          context,
          MaterialPageRoute(builder: (context) => EditRestaurantScreen(restaurante: restaurante)),
        );
        if (updatedRestaurante != null) {
          if (updatedRestaurante.id != null &&
              (updatedRestaurante.id!.startsWith('demo-') || updatedRestaurante.id!.startsWith('rest-'))) {
            final idx = _demoRestaurantes.indexWhere((r) => r.id == updatedRestaurante.id);
            if (idx != -1) {
              setState(() => _demoRestaurantes[idx] = updatedRestaurante);
            }
          } else {
            await _loadAll();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restaurante "${updatedRestaurante.nombre}" guardado con éxito.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (changed == true) {
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _perfil?.nombre.isNotEmpty == true ? _perfil!.nombre : 'Diplomante';
    final initials = nombre.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();

    final filteredList = _filteredCardData;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF9F6),
      drawer: _buildDrawer(nombre, context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: const Color(0xFF26674B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, size: 22),
        label: Text(
          _selectedTipo == TurismoTipo.hotel
              ? 'Nuevo hotel'
              : _selectedTipo == TurismoTipo.evento
                  ? 'Nuevo evento'
                  : _selectedTipo == TurismoTipo.restaurante
                      ? 'Nuevo restaurante'
                      : 'Nuevo · ${_selectedTipo.etiqueta}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
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
            Expanded(child: _buildListBody(filteredList)),
            _buildNoticeBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(List<_CardData> filteredList) {
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
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: filteredList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredList.length,
              itemBuilder: (context, index) => _buildPlaceCard(filteredList[index]),
            ),
    );
  }

  Widget _buildTopAppBar(String initials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: Color(0xFF0C3D28), shape: BoxShape.circle),
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
          ),
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
                  Text(
                    _selectedTipo.etiqueta,
                    style: const TextStyle(
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
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFE2ECE7), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(color: Color(0xFF1B5A3F), fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryTabs() {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: TurismoTipo.values.length,
            itemBuilder: (context, index) {
              final tipo = TurismoTipo.values[index];
              final isSelected = _selectedTipo == tipo;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTipo = tipo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0C3D28) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: isSelected ? const Color(0xFF0C3D28) : Colors.grey.shade200),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tipo.etiqueta,
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
        ),
        const SizedBox(height: 8),
        _buildScrollIndicator(),
      ],
    );
  }

  Widget _buildScrollIndicator() {
    double alignmentFactor;
    switch (_selectedTipo) {
      case TurismoTipo.lugar:
        alignmentFactor = 0.05;
        break;
      case TurismoTipo.actividad:
        alignmentFactor = 0.24;
        break;
      case TurismoTipo.gastronomia:
        alignmentFactor = 0.43;
        break;
      case TurismoTipo.hotel:
        alignmentFactor = 0.62;
        break;
      case TurismoTipo.evento:
        alignmentFactor = 0.81;
        break;
      case TurismoTipo.restaurante:
        alignmentFactor = 1.0;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.arrow_left, size: 14, color: Colors.grey.shade400),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment((alignmentFactor * 2) - 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.38,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Icon(Icons.arrow_right, size: 14, color: Colors.grey.shade400),
        ],
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
                  onTap: () => setState(() => _selectedStatusFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26674B) : const Color(0xFFE8F4EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$filter · $count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF26674B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.grey.shade600, size: 20),
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

  Widget _buildPlaceCard(_CardData card) {
    final bool isEvento = _selectedTipo == TurismoTipo.evento || card.fechaBadgeDay != null;
    final bool isHotel = _selectedTipo == TurismoTipo.hotel || card.precioInfo != null;

    if (isEvento) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Badge de fecha en formato calendario
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: card.badgeBgColor ??
                      (card.activo ? const Color(0xFFE2F0E8) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.fechaBadgeDay ?? '01',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: card.badgeTextColor ??
                            (card.activo ? const Color(0xFF26674B) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.fechaBadgeMonth ?? 'ENE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: card.badgeTextColor ??
                            (card.activo ? const Color(0xFF26674B) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Información del evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nombre,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: card.activo ? const Color(0xFF1F2937) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.categoria} · ${card.periodicidad ?? 'anual'}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: card.activo ? const Color(0xFF6B7280) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: card.activo ? const Color(0xFFE8F4EC) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: card.activo
                                ? const Color(0xFF26674B)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            card.activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: card.activo
                                  ? const Color(0xFF26674B)
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción (Editar y Visibilidad)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: card.activo ? const Color(0xFF26674B) : Colors.grey.shade400,
                      size: 21,
                    ),
                    onPressed: () => _openEditor(card),
                  ),
                  IconButton(
                    icon: Icon(
                      card.activo ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: card.activo ? const Color(0xFF26674B) : const Color(0xFF5A9374),
                      size: 21,
                    ),
                    onPressed: () => _toggleVisibility(card),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final bool isRestaurante = _selectedTipo == TurismoTipo.restaurante;
    if (isRestaurante) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Miniatura con color representativo o foto
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: card.thumbnailColor ??
                      (card.activo ? const Color(0xFFB57834) : const Color(0xFFA5ADA8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: card.imagenes.isNotEmpty
                    ? Image.network(
                        card.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: card.thumbnailColor ??
                              (card.activo ? const Color(0xFFB57834) : const Color(0xFFA5ADA8)),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Información del restaurante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nombre,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: card.activo ? const Color(0xFF1F2937) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card.categoria,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: card.activo ? const Color(0xFF6B7280) : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        if (card.calificacion != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: card.activo ? const Color(0xFFE59819) : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            card.calificacion!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: card.activo ? const Color(0xFFB45309) : Colors.grey.shade400,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: card.activo ? const Color(0xFFE8F4EC) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: card.activo
                                    ? const Color(0xFF26674B)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                card.activo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: card.activo
                                      ? const Color(0xFF26674B)
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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

              // Botones de acción (Editar y Visibilidad)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: card.activo ? const Color(0xFF26674B) : Colors.grey.shade400,
                      size: 21,
                    ),
                    onPressed: () => _openEditor(card),
                  ),
                  IconButton(
                    icon: Icon(
                      card.activo ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: card.activo ? const Color(0xFF26674B) : const Color(0xFF5A9374),
                      size: 21,
                    ),
                    onPressed: () => _toggleVisibility(card),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (isHotel) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Miniatura con color representativo o foto
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: card.thumbnailColor ??
                      (card.activo ? const Color(0xFF488463) : const Color(0xFFB0B5B0)),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: card.imagenes.isNotEmpty
                    ? Image.network(
                        card.imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: card.thumbnailColor ??
                              (card.activo ? const Color(0xFF488463) : const Color(0xFFB0B5B0)),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Información del hotel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: card.activo ? const Color(0xFF1F2937) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card.precioInfo != null
                                ? '${card.categoria} · ${card.precioInfo}'
                                : card.categoria,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: card.activo ? const Color(0xFF4B5563) : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        if (card.calificacion != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 14, color: Color(0xFFE59819)),
                          const SizedBox(width: 3),
                          Text(
                            card.calificacion!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: card.activo ? const Color(0xFFE8F4EC) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: card.activo
                                ? const Color(0xFF26674B)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            card.activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: card.activo
                                  ? const Color(0xFF26674B)
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción (Editar y Visibilidad)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: card.activo ? const Color(0xFF26674B) : Colors.grey.shade400,
                      size: 21,
                    ),
                    onPressed: () => _openEditor(card),
                  ),
                  IconButton(
                    icon: Icon(
                      card.activo ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: card.activo ? const Color(0xFF26674B) : const Color(0xFF5A9374),
                      size: 21,
                    ),
                    onPressed: () => _toggleVisibility(card),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final Color badgeBg = card.activo ? const Color(0xFFE5EFEA) : const Color(0xFFEAEAEA);
    final Color badgeTextColor = card.activo ? const Color(0xFF2A7353) : const Color(0xFF777777);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: !card.activo
                  ? Container(
                      color: Colors.grey.shade400,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 28),
                    )
                  : card.imagenes.isNotEmpty
                      ? Image.network(
                          card.imagenes.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CustomPaint(painter: _getPainterForNombre(card.nombre)),
                        )
                      : CustomPaint(painter: _getPainterForNombre(card.nombre)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: card.activo ? const Color(0xFF1F2937) : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.categoria,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: card.activo ? Colors.grey.shade500 : Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: badgeTextColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              card.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: card.activo ? Colors.grey.shade600 : Colors.grey.shade400, size: 22),
                  onPressed: () => _openEditor(card),
                ),
                IconButton(
                  icon: Icon(
                    card.activo ? Icons.visibility : Icons.visibility_off,
                    color: card.activo ? Colors.grey.shade600 : Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () => _toggleVisibility(card),
                ),
              ],
            ),
          ],
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
                Icon(Icons.layers_clear_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No hay elementos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Prueba cambiando el filtro de estado o agregando un nuevo elemento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeBanner() {
    final String mensaje;
    if (_selectedTipo == TurismoTipo.hotel) {
      mensaje =
          'Desactivar un hotel lo oculta de la app (borrado lógico); se puede reactivar cuando quieras. La calificación se calcula sola con las reseñas.';
    } else if (_selectedTipo == TurismoTipo.evento) {
      mensaje =
          'Un evento inactivo no se muestra en la app aunque ya haya pasado la fecha; reactívalo cuando vuelva a celebrarse.';
    } else if (_selectedTipo == TurismoTipo.restaurante) {
      mensaje =
          'Desactivar un restaurante lo oculta de la app (borrado lógico); se puede reactivar cuando quieras. La calificación se calcula sola con las reseñas.';
    } else {
      mensaje =
          'Desactivar un elemento lo oculta de la app (borrado lógico); se puede reactivar cuando quieras.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6EAE0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF26674B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Color(0xFF26674B),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String name, BuildContext context) {
    final rolLabel = _perfil?.esAdministrador == true ? 'Administrador' : 'Editor';

    return Drawer(
      backgroundColor: const Color(0xFFFAF9F6),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0C3D28)),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(color: Color(0xFFE2ECE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Color(0xFF1B5A3F), fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(_perfil?.correo ?? rolLabel),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Rol'),
                  subtitle: Text(rolLabel),
                ),
                ListTile(
                  leading: const Icon(Icons.hotel_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Hoteles'),
                  subtitle: const Text('Hospedajes y alojamientos'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedTipo = TurismoTipo.hotel);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Eventos'),
                  subtitle: const Text('Ferias y fiestas patronales'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedTipo = TurismoTipo.evento);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Restaurantes'),
                  subtitle: const Text('Comida típica y locales'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedTipo = TurismoTipo.restaurante);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Gestión de Usuarios'),
                  subtitle: const Text('Administradores y editores'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('1. Mis registros (BD)'),
                  subtitle: const Text('CRUD de la Sesión 1'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Color(0xFF1B5A3F)),
                  title: const Text('2. Conexión con el mundo'),
                  subtitle: const Text('GPS, clima y mapa'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContextLabScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune, color: Color(0xFF1B5A3F)),
                  title: const Text('3. Preferencias de usuario'),
                  subtitle: const Text('Persistencia local SharedPreferences'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.design_services_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('4. Adaptar a mi proyecto'),
                  subtitle: const Text('Acerca del proyecto'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAdaptationScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Turismo Comarapa v1.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
