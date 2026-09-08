import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/actividad.dart';
import '../models/evento.dart';
import '../models/gastronomia_item.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/restaurante.dart';
import '../repositories/actividad_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lugar_repository.dart';
import '../repositories/restaurante_repository.dart';
import 'activity_detail_screen.dart';
import 'event_detail_screen.dart';
import 'gastronomy_detail_screen.dart';
import 'hotel_detail_screen.dart';
import 'place_detail_screen.dart';
import 'restaurant_detail_screen.dart';

const Color _kPrimary = Color(0xFF1B5A3F);
const Color _kBg = Color(0xFFFAF9F6);

/// Resultado normalizado de cualquiera de las 6 categorías, para poder
/// mostrarlos juntos en una sola lista y navegar al detalle correcto.
class _ResultadoBusqueda {
  const _ResultadoBusqueda({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.imagenUrl,
    required this.icono,
    required this.iconoColor,
    required this.abrirDetalle,
  });

  final String nombre;
  final String descripcion;
  final String categoria;
  final String? imagenUrl;
  final IconData icono;
  final Color iconoColor;
  final WidgetBuilder abrirDetalle;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _cargando = true;
  String _query = '';
  List<_ResultadoBusqueda> _todos = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim());
    });
    _cargarTodo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    try {
      final resultados = await Future.wait<dynamic>([
        context.read<LugarRepository>().fetchActivos(),
        context.read<ActividadRepository>().fetchActivos(),
        context.read<GastronomiaRepository>().fetchActivos(),
        context.read<HotelRepository>().fetchActivos(),
        context.read<EventoRepository>().fetchActivos(),
        context.read<RestauranteRepository>().fetchActivos(),
      ]);

      final lugares = resultados[0] as List<Lugar>;
      final actividades = resultados[1] as List<Actividad>;
      final gastronomia = resultados[2] as List<GastronomiaItem>;
      final hoteles = resultados[3] as List<Hotel>;
      final eventos = resultados[4] as List<Evento>;
      final restaurantes = resultados[5] as List<Restaurante>;

      final todos = <_ResultadoBusqueda>[
        for (final l in lugares)
          _ResultadoBusqueda(
            nombre: l.nombre,
            descripcion: l.categoriaNombre ?? 'Lugar',
            categoria: 'Lugar',
            imagenUrl: l.imagenes.isNotEmpty ? l.imagenes.first : null,
            icono: Icons.location_on_outlined,
            iconoColor: _kPrimary,
            abrirDetalle: (_) => PlaceDetailScreen(lugar: l),
          ),
        for (final a in actividades)
          _ResultadoBusqueda(
            nombre: a.nombre,
            descripcion: a.categoriaNombre ?? 'Actividad',
            categoria: 'Actividad',
            imagenUrl: a.imagenes.isNotEmpty ? a.imagenes.first : null,
            icono: Icons.explore_outlined,
            iconoColor: _kPrimary,
            abrirDetalle: (_) => ActivityDetailScreen(actividad: a),
          ),
        for (final g in gastronomia)
          _ResultadoBusqueda(
            nombre: g.nombre,
            descripcion: g.categoriaNombre ?? 'Gastronomía',
            categoria: 'Gastronomía',
            imagenUrl: g.imagenes.isNotEmpty ? g.imagenes.first : null,
            icono: Icons.restaurant_menu_outlined,
            iconoColor: const Color(0xFFC68B59),
            abrirDetalle: (_) => GastronomyDetailScreen(item: g),
          ),
        for (final h in hoteles)
          _ResultadoBusqueda(
            nombre: h.nombre,
            descripcion: h.categoriaNombre ?? 'Hotel',
            categoria: 'Hotel',
            imagenUrl: h.imagenes.isNotEmpty ? h.imagenes.first : null,
            icono: Icons.business_center_outlined,
            iconoColor: _kPrimary,
            abrirDetalle: (_) => HotelDetailScreen(hotel: h),
          ),
        for (final e in eventos)
          _ResultadoBusqueda(
            nombre: e.nombre,
            descripcion: e.categoriaNombre ?? 'Evento',
            categoria: 'Evento',
            imagenUrl: e.imagenes.isNotEmpty ? e.imagenes.first : null,
            icono: Icons.calendar_today_outlined,
            iconoColor: _kPrimary,
            abrirDetalle: (_) => EventDetailScreen(evento: e),
          ),
        for (final r in restaurantes)
          _ResultadoBusqueda(
            nombre: r.nombre,
            descripcion: r.categoriaNombre ?? 'Restaurante',
            categoria: 'Restaurante',
            imagenUrl: r.imagenes.isNotEmpty ? r.imagenes.first : null,
            icono: Icons.restaurant_outlined,
            iconoColor: const Color(0xFFC68B59),
            abrirDetalle: (_) => RestaurantDetailScreen(restaurante: r),
          ),
      ];

      if (!mounted) return;
      setState(() {
        _todos = todos;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  List<_ResultadoBusqueda> get _filtrados {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return _todos.where((r) {
      return r.nombre.toLowerCase().contains(q) ||
          r.categoria.toLowerCase().contains(q) ||
          r.descripcion.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar lugares, hoteles, eventos...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                  onPressed: () => _controller.clear(),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Busca lugares, actividades, gastronomía,\nhoteles, eventos o restaurantes',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final resultados = _filtrados;

    if (resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No se encontraron resultados para "$_query"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: resultados.length,
      itemBuilder: (context, index) => _buildResultCard(resultados[index]),
    );
  }

  Widget _buildResultCard(_ResultadoBusqueda resultado) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: resultado.abrirDetalle),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: resultado.iconoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: resultado.imagenUrl != null
                  ? Image.network(
                      resultado.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(resultado.icono, color: resultado.iconoColor),
                    )
                  : Icon(resultado.icono, color: resultado.iconoColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultado.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: resultado.iconoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resultado.categoria,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: resultado.iconoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
