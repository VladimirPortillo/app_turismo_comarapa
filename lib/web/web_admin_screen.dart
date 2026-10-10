import 'dart:math' as math;

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
import '../screens/edit_event_screen.dart';
import '../screens/edit_hotel_screen.dart';
import '../screens/edit_place_screen.dart';
import '../screens/edit_restaurant_screen.dart';
import '../screens/login_screen.dart' show MountainLogoPainter;
import '../screens/new_event_screen.dart';
import '../screens/new_hotel_screen.dart';
import '../screens/new_restaurant_screen.dart';
import 'web_activity_detail_screen.dart';
import '../widgets/paginador.dart';
import 'web_admin_users.dart';
import 'web_components.dart';
import 'web_event_detail_screen.dart';
import 'web_events_screen.dart' show fechaCorta;
import 'web_gastronomy_detail_screen.dart';
import 'web_hotel_detail_screen.dart';
import 'web_hotels_screen.dart' show preciosHotel;
import 'web_login_screen.dart';
import 'web_place_detail_screen.dart';
import 'web_restaurant_detail_screen.dart';
import 'web_theme.dart';

/// Abre una pantalla de la app (formularios de crear / editar) dentro de
/// una ventana centrada, para que en web no ocupe toda la pantalla.
/// Devuelve lo mismo que devuelva la pantalla al cerrarse.
Future<T?> abrirEnVentana<T>(BuildContext context, Widget pantalla) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) {
        final pantallaCompleta = MediaQuery.of(context);
        final size = pantallaCompleta.size;
        // En pantallas angostas la ventana ocupa toda la pantalla.
        final angosta = size.width < 640;
        final alto = angosta ? size.height : size.height * 0.92;
        final ancho = angosta ? size.width : math.min(760.0, size.width - 32);
        return Center(
          child: SizedBox(
            width: ancho,
            height: alto,
            child: Material(
              borderRadius: BorderRadius.circular(angosta ? 0 : 20),
              clipBehavior: Clip.antiAlias,
              elevation: 24,
              // Las pantallas de la app se adaptan al tamaño de la ventana.
              child: MediaQuery(
                data: pantallaCompleta.copyWith(size: Size(ancho, alto)),
                child: pantalla,
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    ),
  );
}

/// Fila de la tabla: datos comunes de cualquier tipo de contenido.
class _Fila {
  const _Fila({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.activo,
    required this.imagenes,
    required this.original,
    this.detalle,
    this.calificacion,
  });

  final String id;
  final String nombre;
  final String categoria;
  final bool activo;
  final List<String> imagenes;
  final String? detalle;
  final num? calificacion;

  /// El modelo original (Lugar, Hotel, Evento...).
  final Object original;
}

enum _Estado {
  todos('Todos'),
  activos('Publicados'),
  inactivos('Ocultos');

  const _Estado(this.label);
  final String label;
}

/// Panel de administración para la versión web de escritorio.
class WebAdminScreen extends StatefulWidget {
  const WebAdminScreen({super.key, this.initialTipo = TurismoTipo.lugar});

  final TurismoTipo initialTipo;

  @override
  State<WebAdminScreen> createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  late TurismoTipo _tipo = widget.initialTipo;

  /// true = se muestra la gestión de usuarios en lugar del contenido.
  bool _usuarios = false;

  _Estado _estado = _Estado.todos;
  String _query = '';
  bool _ordenAsc = true;
  int _pagina = 0;

  bool _loading = true;
  bool _refrescando = false;
  String? _error;
  UsuarioPerfil? _perfil;

  List<Lugar> _lugares = <Lugar>[];
  List<Actividad> _actividades = <Actividad>[];
  List<GastronomiaItem> _gastronomia = <GastronomiaItem>[];
  List<Hotel> _hoteles = <Hotel>[];
  List<Evento> _eventos = <Evento>[];
  List<Restaurante> _restaurantes = <Restaurante>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _pagina = 0;
      });
    });
    _cargar();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await context.read<UsuarioRepository>().fetchCurrent();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Informativo: si falla, el panel sigue funcionando.
    }
  }

  /// Carga todo el contenido. Con [silencioso] no oculta la tabla actual.
  Future<void> _cargar({bool silencioso = false}) async {
    setState(() {
      if (silencioso) {
        _refrescando = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    Future<List<T>> opcional<T>(Future<List<T>> Function() f) async {
      // Igual que en la app: eventos y restaurantes pueden no estar migrados.
      try {
        return await f();
      } catch (_) {
        return <T>[];
      }
    }

    try {
      final r = await Future.wait<dynamic>([
        context.read<LugarRepository>().fetchAll(),
        context.read<ActividadRepository>().fetchAll(),
        context.read<GastronomiaRepository>().fetchAll(),
        context.read<HotelRepository>().fetchAll(),
        opcional(context.read<EventoRepository>().fetchAll),
        opcional(context.read<RestauranteRepository>().fetchAll),
      ]);
      if (!mounted) return;
      setState(() {
        _lugares = r[0] as List<Lugar>;
        _actividades = r[1] as List<Actividad>;
        _gastronomia = r[2] as List<GastronomiaItem>;
        _hoteles = r[3] as List<Hotel>;
        _eventos = r[4] as List<Evento>;
        _restaurantes = r[5] as List<Restaurante>;
        _loading = false;
        _refrescando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _refrescando = false;
      });
    }
  }

  // ------------------------------------------------------------- Datos

  List<_Fila> _filasDe(TurismoTipo tipo) {
    switch (tipo) {
      case TurismoTipo.lugar:
        return [
          for (final e in _lugares)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Sin categoría',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle: textoONulo(e.direccionReferencia),
              original: e,
            ),
        ];
      case TurismoTipo.actividad:
        return [
          for (final e in _actividades)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Sin categoría',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle: textoONulo(precioBs(e.precioReferencial)),
              original: e,
            ),
        ];
      case TurismoTipo.gastronomia:
        return [
          for (final e in _gastronomia)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Sin categoría',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle:
                  textoONulo(e.restauranteNombre) ??
                  textoONulo(precioBs(e.precioReferencial)),
              original: e,
            ),
        ];
      case TurismoTipo.hotel:
        return [
          for (final e in _hoteles)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Hotel',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle: textoONulo(preciosHotel(e)),
              calificacion: e.calificacionPromedio > 0
                  ? e.calificacionPromedio
                  : null,
              original: e,
            ),
        ];
      case TurismoTipo.evento:
        return [
          for (final e in _eventos)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Evento',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle: '${fechaCorta(e)} · ${e.periodicidad ?? 'anual'}',
              original: e,
            ),
        ];
      case TurismoTipo.restaurante:
        return [
          for (final e in _restaurantes)
            _Fila(
              id: e.id ?? '',
              nombre: e.nombre,
              categoria: e.categoriaNombre ?? 'Restaurante',
              activo: e.activo,
              imagenes: e.imagenes,
              detalle: textoONulo(e.horarioAtencion),
              calificacion: e.calificacionPromedio > 0
                  ? e.calificacionPromedio
                  : null,
              original: e,
            ),
        ];
    }
  }

  List<_Fila> get _filas => _filasDe(_tipo);

  List<_Fila> get _filasVisibles {
    final lista =
        _filas.where((f) {
          final okEstado = switch (_estado) {
            _Estado.todos => true,
            _Estado.activos => f.activo,
            _Estado.inactivos => !f.activo,
          };
          final okTexto =
              f.nombre.toLowerCase().contains(_query) ||
              f.categoria.toLowerCase().contains(_query);
          return okEstado && okTexto;
        }).toList()..sort((a, b) {
          final c = a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
          return _ordenAsc ? c : -c;
        });
    return lista;
  }

  // ---------------------------------------------------------- Acciones

  Future<void> _cambiarVisibilidad(
    _Fila fila, {
    bool mostrarDeshacer = true,
  }) async {
    final nuevo = !fila.activo;
    try {
      switch (_tipo) {
        case TurismoTipo.lugar:
          await context.read<LugarRepository>().setActivo(fila.id, nuevo);
        case TurismoTipo.actividad:
          await context.read<ActividadRepository>().setActivo(fila.id, nuevo);
        case TurismoTipo.gastronomia:
          await context.read<GastronomiaRepository>().setActivo(fila.id, nuevo);
        case TurismoTipo.hotel:
          await context.read<HotelRepository>().setActivo(fila.id, nuevo);
        case TurismoTipo.evento:
          await context.read<EventoRepository>().setActivo(fila.id, nuevo);
        case TurismoTipo.restaurante:
          await context.read<RestauranteRepository>().setActivo(fila.id, nuevo);
      }
      await _cargar(silencioso: true);
      if (!mounted || !mostrarDeshacer) return;
      final tipoActual = _tipo;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: anchoSnackBar(context),
          content: Text(
            nuevo
                ? '"${fila.nombre}" ahora es visible en el sitio.'
                : '"${fila.nombre}" se ocultó del sitio.',
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              if (_tipo != tipoActual) return;
              final actualizada = _filas
                  .where((f) => f.id == fila.id)
                  .firstOrNull;
              if (actualizada != null) {
                _cambiarVisibilidad(actualizada, mostrarDeshacer: false);
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $error')));
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        width: anchoSnackBar(context),
      ),
    );
  }

  /// Abre el formulario de la app (crear si [fila] es null, si no editar).
  Future<void> _abrirEditor([_Fila? fila]) async {
    final original = fila?.original;
    switch (_tipo) {
      case TurismoTipo.lugar:
      case TurismoTipo.actividad:
      case TurismoTipo.gastronomia:
        final cambio = await abrirEnVentana<bool>(
          context,
          EditPlaceScreen(
            tipo: _tipo,
            lugar: original is Lugar ? original : null,
            actividad: original is Actividad ? original : null,
            gastronomia: original is GastronomiaItem ? original : null,
          ),
        );
        if (cambio == true) await _cargar(silencioso: true);
      case TurismoTipo.hotel:
        final hotel = await abrirEnVentana<Hotel>(
          context,
          original is Hotel
              ? EditHotelScreen(hotel: original)
              : const NewHotelScreen(),
        );
        if (hotel != null) {
          await _cargar(silencioso: true);
          _avisar('Hotel "${hotel.nombre}" guardado con éxito.');
        }
      case TurismoTipo.evento:
        final evento = await abrirEnVentana<Evento>(
          context,
          original is Evento
              ? EditEventScreen(evento: original)
              : const NewEventScreen(),
        );
        if (evento != null) {
          await _cargar(silencioso: true);
          _avisar('Evento "${evento.nombre}" guardado con éxito.');
        }
      case TurismoTipo.restaurante:
        final restaurante = await abrirEnVentana<Restaurante>(
          context,
          original is Restaurante
              ? EditRestaurantScreen(restaurante: original)
              : const NewRestaurantScreen(),
        );
        if (restaurante != null) {
          await _cargar(silencioso: true);
          _avisar('Restaurante "${restaurante.nombre}" guardado con éxito.');
        }
    }
  }

  /// Abre la página pública (versión web) del elemento.
  void _verEnSitio(_Fila fila) {
    final o = fila.original;
    final Widget? pantalla = switch (o) {
      Lugar() => WebPlaceDetailScreen(lugar: o),
      Actividad() => WebActivityDetailScreen(actividad: o),
      GastronomiaItem() => WebGastronomyDetailScreen(item: o),
      Hotel() => WebHotelDetailScreen(hotel: o),
      Evento() => WebEventDetailScreen(evento: o),
      Restaurante() => WebRestaurantDetailScreen(restaurante: o),
      _ => null,
    };
    if (pantalla == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir del panel de administración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WebAuthGate()),
      (route) => route.isFirst,
    );
  }

  // --------------------------------------------------------------- UI

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// true cuando la ventana es angosta: la barra lateral pasa a un drawer.
  bool _compacto = false;

  @override
  Widget build(BuildContext context) {
    _compacto = MediaQuery.sizeOf(context).width < kAnchoPanelEscritorio;
    final principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        Expanded(
          child: _usuarios
              ? WebAdminUsersPanel(perfilActual: _perfil)
              : _buildContenido(),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F4F1),
      drawer: _compacto
          ? Drawer(
              width: 280,
              backgroundColor: WebTheme.verdeOscuro,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(child: _buildSidebar()),
            )
          : null,
      body: _compacto
          ? principal
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(),
                Expanded(child: principal),
              ],
            ),
    );
  }

  // ------------------------------------------------------- Barra lateral

  static IconData _iconoTipo(TurismoTipo tipo) => switch (tipo) {
    TurismoTipo.lugar => Icons.location_on_outlined,
    TurismoTipo.actividad => Icons.explore_outlined,
    TurismoTipo.gastronomia => Icons.restaurant_menu_outlined,
    TurismoTipo.hotel => Icons.hotel_outlined,
    TurismoTipo.evento => Icons.calendar_today_outlined,
    TurismoTipo.restaurante => Icons.storefront_outlined,
  };

  Widget _buildSidebar() {
    return Container(
      width: _compacto ? null : 260,
      color: WebTheme.verdeOscuro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                CustomPaint(
                  size: const Size(28, 22),
                  painter: MountainLogoPainter(),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comarapa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      'PANEL ADMIN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _tituloSidebar('Contenido'),
                for (final tipo in TurismoTipo.values)
                  _itemSidebar(
                    icono: _iconoTipo(tipo),
                    label: tipo.etiqueta,
                    cantidad: _loading ? null : _filasDe(tipo).length,
                    seleccionado: !_usuarios && _tipo == tipo,
                    onTap: () => setState(() {
                      _usuarios = false;
                      _tipo = tipo;
                      _estado = _Estado.todos;
                      _pagina = 0;
                      _searchController.clear();
                    }),
                  ),
                if (_perfil?.esAdministrador == true) ...[
                  const SizedBox(height: 16),
                  _tituloSidebar('Administración'),
                  _itemSidebar(
                    icono: Icons.people_alt_outlined,
                    label: 'Usuarios',
                    seleccionado: _usuarios,
                    onTap: () => setState(() => _usuarios = true),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _itemSidebar(
                  icono: Icons.logout,
                  label: 'Cerrar sesión',
                  color: const Color(0xFFFCA5A5),
                  onTap: _cerrarSesion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSidebar(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _itemSidebar({
    required IconData icono,
    required String label,
    required VoidCallback onTap,
    int? cantidad,
    bool seleccionado = false,
    Color? color,
  }) {
    final c = color ?? (seleccionado ? Colors.white : Colors.white70);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: seleccionado
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // En modo compacto, cierra el menú desplegable al elegir.
            _scaffoldKey.currentState?.closeDrawer();
            onTap();
          },
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icono, size: 20, color: c),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: c,
                      fontWeight: seleccionado
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (cantidad != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ Barra superior

  Widget _buildTopBar() {
    final nombre = textoONulo(_perfil?.nombre) ?? 'Administrador';
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();
    final rol = _perfil?.esAdministrador == true ? 'Administrador' : 'Editor';

    return Container(
      height: 72,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: _compacto ? 8 : 32),
      child: Row(
        children: [
          if (_compacto)
            IconButton(
              tooltip: 'Menú',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: WebTheme.verdeOscuro),
            ),
          if (!_compacto) ...[
            Text('Panel', style: TextStyle(color: Colors.grey.shade500)),
            Text('  /  ', style: TextStyle(color: Colors.grey.shade400)),
          ],
          Flexible(
            child: Text(
              _usuarios ? 'Usuarios' : _tipo.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WebTheme.verdeOscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (!_usuarios) ...[
            if (_refrescando)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _loading ? null : () => _cargar(silencioso: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
          SizedBox(width: _compacto ? 4 : 16),
          Tooltip(
            message: '$nombre\n${_perfil?.correo ?? rol}',
            child: CircleAvatar(
              radius: 19,
              backgroundColor: WebTheme.verdeClaro,
              child: Text(
                iniciales,
                style: const TextStyle(
                  color: WebTheme.verde,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (_compacto) const SizedBox(width: 8),
          if (!_compacto) const SizedBox(width: 10),
          if (!_compacto)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  _perfil?.correo ?? rol,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Contenido

  Widget _buildContenido() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final todas = _filas;
    final visibles = _filasVisibles;
    final activos = todas.where((f) => f.activo).length;
    final sinFotos = todas.where((f) => f.imagenes.isEmpty).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_compacto ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tipo.etiqueta,
            style: TextStyle(
              fontSize: _compacto ? 26 : 32,
              fontWeight: FontWeight.bold,
              color: WebTheme.verdeOscuro,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea, edita y controla qué se publica en el sitio.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          WebStatsGrid(
            espacio: _compacto ? 12 : 16,
            children: [
              _stat(
                'Total',
                '${todas.length}',
                Icons.layers_outlined,
                WebTheme.verdeOscuro,
              ),
              _stat(
                'Publicados',
                '$activos',
                Icons.visibility_outlined,
                const Color(0xFF16A34A),
              ),
              _stat(
                'Ocultos',
                '${todas.length - activos}',
                Icons.visibility_off_outlined,
                Colors.grey.shade600,
              ),
              _stat(
                'Sin fotos',
                '$sinFotos',
                Icons.hide_image_outlined,
                const Color(0xFFD97706),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildToolbar(todas.length, activos),
          const SizedBox(height: 16),
          _buildTabla(paginar(visibles, _pagina)),
          Paginador(
            pagina: _pagina,
            total: visibles.length,
            color: WebTheme.verde,
            onCambiar: (p) => setState(() => _pagina = p),
          ),
        ],
      ),
    );
  }

  Widget _stat(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(_compacto ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int total, int activos) {
    final conteo = {
      _Estado.todos: total,
      _Estado.activos: activos,
      _Estado.inactivos: total - activos,
    };
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final filtros = SegmentedButton<_Estado>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: WebTheme.verdeClaro,
        selectedForegroundColor: WebTheme.verde,
      ),
      segments: [
        for (final e in _Estado.values)
          ButtonSegment(value: e, label: Text('${e.label} · ${conteo[e]}')),
      ],
      selected: {_estado},
      onSelectionChanged: (s) => setState(() {
        _estado = s.first;
        _pagina = 0;
      }),
    );
    final buscador = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por nombre o categoría...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _searchController.clear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: borde,
        enabledBorder: borde,
      ),
    );
    final botonNuevo = FilledButton.icon(
      onPressed: () => _abrirEditor(),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF26674B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add),
      label: Text(switch (_tipo) {
        TurismoTipo.hotel => 'Nuevo hotel',
        TurismoTipo.evento => 'Nuevo evento',
        TurismoTipo.restaurante => 'Nuevo restaurante',
        TurismoTipo.actividad => 'Nueva actividad',
        TurismoTipo.gastronomia => 'Nuevo plato',
        TurismoTipo.lugar => 'Nuevo lugar',
      }, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        if (ancho >= kAnchoPanelEscritorio) {
          return Row(
            children: [
              filtros,
              const SizedBox(width: 16),
              SizedBox(width: 300, child: buscador),
              const Spacer(),
              botonNuevo,
            ],
          );
        }
        // Pantallas angostas: filtros, buscador y botón se apilan.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: filtros,
            ),
            const SizedBox(height: 12),
            if (ancho >= 520)
              Row(
                children: [
                  Expanded(child: buscador),
                  const SizedBox(width: 12),
                  botonNuevo,
                ],
              )
            else ...[
              buscador,
              const SizedBox(height: 12),
              botonNuevo,
            ],
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------- Tabla

  static const double _anchoAcciones = 110;
  static const double _anchoEstado = 170;

  Widget _buildTabla(List<_Fila> filas) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildTablaCon(
        filas,
        compacta: constraints.maxWidth < kAnchoTablaCompleta,
      ),
    );
  }

  Widget _buildTablaCon(List<_Fila> filas, {required bool compacta}) {
    final estiloCabecera = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: Colors.grey.shade600,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compacta)
            Container(
              color: WebTheme.fondo,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () => setState(() => _ordenAsc = !_ordenAsc),
                      child: Row(
                        children: [
                          Text('NOMBRE', style: estiloCabecera),
                          const SizedBox(width: 4),
                          Icon(
                            _ordenAsc
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('CATEGORÍA', style: estiloCabecera),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('DETALLE', style: estiloCabecera),
                  ),
                  SizedBox(
                    width: _anchoEstado,
                    child: Text('PUBLICADO', style: estiloCabecera),
                  ),
                  SizedBox(
                    width: _anchoAcciones,
                    child: Text(
                      'ACCIONES',
                      textAlign: TextAlign.right,
                      style: estiloCabecera,
                    ),
                  ),
                ],
              ),
            ),
          if (filas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.layers_clear_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay elementos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: WebTheme.texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prueba cambiando el filtro o agrega un nuevo elemento.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < filas.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
              _FilaTabla(
                fila: filas[i],
                compacta: compacta,
                anchoEstado: _anchoEstado,
                anchoAcciones: _anchoAcciones,
                onEditar: () => _abrirEditor(filas[i]),
                onVer: () => _verEnSitio(filas[i]),
                onCambiarVisibilidad: () => _cambiarVisibilidad(filas[i]),
              ),
            ],
        ],
      ),
    );
  }
}

class _FilaTabla extends StatefulWidget {
  const _FilaTabla({
    required this.fila,
    required this.anchoEstado,
    required this.anchoAcciones,
    required this.onEditar,
    required this.onVer,
    required this.onCambiarVisibilidad,
    this.compacta = false,
  });

  final _Fila fila;

  /// true = se muestra como tarjeta apilada (pantallas angostas).
  final bool compacta;
  final double anchoEstado;
  final double anchoAcciones;
  final VoidCallback onEditar;
  final VoidCallback onVer;
  final VoidCallback onCambiarVisibilidad;

  @override
  State<_FilaTabla> createState() => _FilaTablaState();
}

class _FilaTablaState extends State<_FilaTabla> {
  bool _hover = false;

  Widget _miniatura(_Fila f, {double tam = 48}) {
    return Opacity(
      opacity: f.activo ? 1 : 0.5,
      child: Container(
        width: tam,
        height: tam,
        decoration: BoxDecoration(
          color: WebTheme.verdeClaro,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: f.imagenes.isNotEmpty
            ? Image.network(
                f.imagenes.first,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_outlined, color: WebTheme.verde),
              )
            : const Icon(Icons.image_outlined, color: WebTheme.verde),
      ),
    );
  }

  /// Versión tarjeta para pantallas angostas: misma información y acciones.
  Widget _buildTarjeta() {
    final f = widget.fila;
    final apagado = !f.activo;
    final colorTexto = apagado ? Colors.grey.shade400 : const Color(0xFF1F2937);

    return InkWell(
      onTap: widget.onEditar,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniatura(f, tam: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Opacity(
                            opacity: apagado ? 0.5 : 1,
                            child: WebBadge(texto: f.categoria),
                          ),
                          if (f.calificacion != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: Color(0xFFE59819),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  f.calificacion!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (f.detalle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          f.detalle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: apagado
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: f.activo,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF26674B),
                  onChanged: (_) => widget.onCambiarVisibilidad(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f.activo ? 'Publicado' : 'Oculto',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: f.activo
                          ? const Color(0xFF26674B)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ver en el sitio',
                  onPressed: widget.onVer,
                  icon: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: widget.onEditar,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF26674B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compacta) return _buildTarjeta();
    final f = widget.fila;
    final apagado = !f.activo;
    final colorTexto = apagado ? Colors.grey.shade400 : const Color(0xFF1F2937);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: widget.onEditar,
        child: Container(
          color: _hover ? const Color(0xFFF7FAF8) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _miniatura(f),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          if (f.calificacion != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: Color(0xFFE59819),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  f.calificacion!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: apagado ? 0.5 : 1,
                    child: WebBadge(texto: f.categoria),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  f.detalle ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: apagado
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(
                width: widget.anchoEstado,
                child: Row(
                  children: [
                    Tooltip(
                      message: f.activo
                          ? 'Ocultar del sitio'
                          : 'Publicar en el sitio',
                      child: Switch(
                        value: f.activo,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF26674B),
                        onChanged: (_) => widget.onCambiarVisibilidad(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f.activo ? 'Publicado' : 'Oculto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: f.activo
                            ? const Color(0xFF26674B)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: widget.anchoAcciones,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Ver en el sitio',
                      onPressed: widget.onVer,
                      icon: Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: widget.onEditar,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xFF26674B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
