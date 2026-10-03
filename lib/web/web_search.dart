import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/actividad.dart';
import '../models/evento.dart';
import '../models/gastronomia_item.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/restaurante.dart';
import '../models/turismo_tipo.dart' show dificultadLabel;
import '../repositories/actividad_repository.dart';
import '../repositories/evento_repository.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lugar_repository.dart';
import '../repositories/restaurante_repository.dart';
import 'web_activities_screen.dart' show nivelDificultad;
import 'web_activity_detail_screen.dart';
import 'web_components.dart' show precioBs, textoONulo;
import 'web_event_detail_screen.dart';
import 'web_events_screen.dart' show fechaCorta, periodicidadTexto;
import 'web_gastronomy_detail_screen.dart';
import 'web_hotel_detail_screen.dart';
import 'web_hotels_screen.dart' show preciosHotel;
import 'web_place_detail_screen.dart';
import 'web_restaurant_detail_screen.dart';
import 'web_theme.dart';
import 'web_widgets.dart' show duracionLabel;

/// Abre el buscador global web como ventana flotante modal.
Future<void> showWebSearch(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar búsqueda',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => const _WebSearchDialog(),
    transitionBuilder: (_, animation, _, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curva),
          child: child,
        ),
      );
    },
  );
}

/// Botón con forma de caja de búsqueda para la barra de navegación web.
class WebSearchButton extends StatelessWidget {
  const WebSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WebTheme.fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showWebSearch(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text('Buscar...', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(width: 28),
              const _KeyBadge('Ctrl K'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Categorías del filtro horizontal con icono asociado.
enum _Tipo {
  lugar('Lugares', Icons.location_on_outlined),
  actividad('Actividades', Icons.calendar_month_outlined),
  gastronomia('Gastronomía', Icons.restaurant_outlined),
  hotel('Hoteles', Icons.hotel_outlined),
  restaurante('Restaurantes', Icons.dinner_dining_outlined),
  evento('Eventos', Icons.celebration_outlined);

  const _Tipo(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}

/// Dato corto que se muestra bajo el título (duración, precio, fecha...).
typedef _Dato = ({IconData icono, String texto});

/// Entidad unificada para representar cualquier resultado de búsqueda.
/// Todos los campos salen de la base de datos; los que no tienen valor
/// quedan en null / vacíos y no se muestran.
class _Resultado {
  const _Resultado({
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.badgeTexto,
    required this.abrirDetalle,
    this.ubicacion,
    this.datos = const <_Dato>[],
  });

  final _Tipo tipo;
  final String nombre;
  final String? ubicacion;
  final List<_Dato> datos;
  final String descripcion;
  final String? imagenUrl;
  final String badgeTexto;
  final WidgetBuilder abrirDetalle;

  IconData get badgeIcono => tipo.icono;

  bool coincide(String q) {
    return nombre.toLowerCase().contains(q) ||
        (ubicacion ?? '').toLowerCase().contains(q) ||
        descripcion.toLowerCase().contains(q) ||
        badgeTexto.toLowerCase().contains(q) ||
        tipo.etiqueta.toLowerCase().contains(q);
  }
}

class _WebSearchDialog extends StatefulWidget {
  const _WebSearchDialog();

  @override
  State<_WebSearchDialog> createState() => _WebSearchDialogState();
}

class _WebSearchDialogState extends State<_WebSearchDialog> {
  static const double _altoItem = 100;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _cargando = true;
  bool _error = false;
  String _query = '';
  _Tipo? _filtro;
  int _seleccionado = 0;
  List<_Resultado> _todos = <_Resultado>[];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final texto = _controller.text.trim();
      if (texto == _query) return;
      setState(() {
        _query = texto;
        _seleccionado = 0;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    _cargarTodo();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Tipos que no se pudieron cargar (se avisa, pero se muestra el resto).
  List<_Tipo> _fallidos = <_Tipo>[];

  /// Carga cada tabla por separado desde la base de datos: si una falla,
  /// las demás igual se muestran.
  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = false;
      _fallidos = <_Tipo>[];
    });

    final fallidos = <_Tipo>[];
    Future<List<T>> cargar<T>(_Tipo tipo, Future<List<T>> Function() f) async {
      try {
        return await f();
      } catch (_) {
        fallidos.add(tipo);
        return <T>[];
      }
    }

    final r = await Future.wait<dynamic>([
      cargar(_Tipo.lugar, context.read<LugarRepository>().fetchActivos),
      cargar(_Tipo.actividad, context.read<ActividadRepository>().fetchActivos),
      cargar(_Tipo.gastronomia,
          context.read<GastronomiaRepository>().fetchActivos),
      cargar(_Tipo.hotel, context.read<HotelRepository>().fetchActivos),
      cargar(_Tipo.restaurante,
          context.read<RestauranteRepository>().fetchActivos),
      cargar(_Tipo.evento, context.read<EventoRepository>().fetchActivos),
    ]);

    String? primera(List<String> imgs) => imgs.isNotEmpty ? imgs.first : null;
    String? calificacion(num c) => c > 0 ? c.toStringAsFixed(1) : null;

    final todos = <_Resultado>[
      for (final l in r[0] as List<Lugar>)
        _Resultado(
          tipo: _Tipo.lugar,
          nombre: l.nombre,
          ubicacion: textoONulo(l.direccionReferencia),
          datos: [
            if ((l.tiempoVisitaMin ?? 0) > 0)
              (icono: Icons.access_time, texto: duracionLabel(l.tiempoVisitaMin)),
            (
              icono: Icons.terrain,
              texto: dificultadLabel(nivelDificultad(l.dificultad)),
            ),
            (icono: Icons.payments_outlined, texto: precioBs(l.costoEntrada)),
          ],
          descripcion: l.descripcion,
          imagenUrl: primera(l.imagenes),
          badgeTexto: textoONulo(l.categoriaNombre) ?? 'Lugar',
          abrirDetalle: (_) => WebPlaceDetailScreen(lugar: l),
        ),
      for (final a in r[1] as List<Actividad>)
        _Resultado(
          tipo: _Tipo.actividad,
          nombre: a.nombre,
          datos: [
            if ((a.duracionMin ?? 0) > 0)
              (icono: Icons.access_time, texto: duracionLabel(a.duracionMin)),
            (
              icono: Icons.terrain,
              texto: dificultadLabel(nivelDificultad(a.dificultad)),
            ),
            if (a.precioReferencial != null)
              (
                icono: Icons.payments_outlined,
                texto: precioBs(a.precioReferencial),
              ),
          ],
          descripcion: a.descripcion,
          imagenUrl: primera(a.imagenes),
          badgeTexto: textoONulo(a.categoriaNombre) ?? 'Actividad',
          abrirDetalle: (_) => WebActivityDetailScreen(actividad: a),
        ),
      for (final g in r[2] as List<GastronomiaItem>)
        _Resultado(
          tipo: _Tipo.gastronomia,
          nombre: g.nombre,
          ubicacion: textoONulo(g.restauranteNombre),
          datos: [
            if (g.precioReferencial != null)
              (
                icono: Icons.payments_outlined,
                texto: precioBs(g.precioReferencial),
              ),
            if (textoONulo(g.temporada) != null)
              (icono: Icons.event, texto: g.temporada!.trim()),
          ],
          descripcion: g.descripcion,
          imagenUrl: primera(g.imagenes),
          badgeTexto: textoONulo(g.categoriaNombre) ?? 'Gastronomía',
          abrirDetalle: (_) => WebGastronomyDetailScreen(item: g),
        ),
      for (final h in r[3] as List<Hotel>)
        _Resultado(
          tipo: _Tipo.hotel,
          nombre: h.nombre,
          ubicacion: textoONulo(h.direccionReferencia),
          datos: [
            if (preciosHotel(h).isNotEmpty)
              (icono: Icons.payments_outlined, texto: preciosHotel(h)),
            if (calificacion(h.calificacionPromedio) != null)
              (icono: Icons.star, texto: calificacion(h.calificacionPromedio)!),
            if (h.servicios.isNotEmpty)
              (
                icono: Icons.room_service_outlined,
                texto: '${h.servicios.length} servicios',
              ),
          ],
          descripcion: h.descripcion,
          imagenUrl: primera(h.imagenes),
          badgeTexto: textoONulo(h.categoriaNombre) ?? 'Hotel',
          abrirDetalle: (_) => WebHotelDetailScreen(hotel: h),
        ),
      for (final x in r[4] as List<Restaurante>)
        _Resultado(
          tipo: _Tipo.restaurante,
          nombre: x.nombre,
          ubicacion: textoONulo(x.direccionReferencia),
          datos: [
            if (textoONulo(x.horarioAtencion) != null)
              (icono: Icons.access_time, texto: x.horarioAtencion!.trim()),
            if ((x.precioReferencial ?? 0) > 0)
              (
                icono: Icons.payments_outlined,
                texto: 'Bs ${x.precioReferencial!.toInt()} ref.',
              ),
            if (calificacion(x.calificacionPromedio) != null)
              (icono: Icons.star, texto: calificacion(x.calificacionPromedio)!),
          ],
          descripcion: x.descripcion,
          imagenUrl: primera(x.imagenes),
          badgeTexto: textoONulo(x.categoriaNombre) ?? 'Restaurante',
          abrirDetalle: (_) => WebRestaurantDetailScreen(restaurante: x),
        ),
      for (final e in r[5] as List<Evento>)
        _Resultado(
          tipo: _Tipo.evento,
          nombre: e.nombre,
          datos: [
            (icono: Icons.event_outlined, texto: fechaCorta(e)),
            if (periodicidadTexto(e) != null)
              (icono: Icons.repeat, texto: periodicidadTexto(e)!),
          ],
          descripcion: e.descripcion,
          imagenUrl: primera(e.imagenes),
          badgeTexto: textoONulo(e.categoriaNombre) ?? 'Evento',
          abrirDetalle: (_) => WebEventDetailScreen(evento: e),
        ),
    ];

    if (!mounted) return;
    setState(() {
      _todos = todos;
      _fallidos = fallidos;
      // Error total solo si no se pudo cargar ninguna tabla.
      _error = fallidos.length == _Tipo.values.length;
      _cargando = false;
    });
  }

  List<_Resultado> get _coincidencias {
    if (_query.isEmpty) return _todos;
    final q = _query.toLowerCase();
    final lista = _todos.where((r) => r.coincide(q)).toList();
    lista.sort((a, b) {
      final ai = a.nombre.toLowerCase().startsWith(q) ? 0 : 1;
      final bi = b.nombre.toLowerCase().startsWith(q) ? 0 : 1;
      return ai.compareTo(bi);
    });
    return lista;
  }

  List<_Resultado> get _visibles {
    final lista = _coincidencias;
    if (_filtro == null) return lista;
    return lista.where((r) => r.tipo == _filtro).toList();
  }

  void _mover(int delta) {
    final total = _visibles.length;
    if (total == 0) return;
    setState(() => _seleccionado = (_seleccionado + delta).clamp(0, total - 1));

    if (!_scroll.hasClients) return;
    final arriba = _seleccionado * _altoItem;
    final abajo = arriba + _altoItem;
    final pos = _scroll.position;
    if (arriba < pos.pixels) {
      _scroll.jumpTo(arriba);
    } else if (abajo > pos.pixels + pos.viewportDimension) {
      _scroll.jumpTo(abajo - pos.viewportDimension);
    }
  }

  void _abrir(_Resultado resultado) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: resultado.abrirDetalle));
  }

  void _abrirSeleccionado() {
    final lista = _visibles;
    if (_seleccionado < lista.length) _abrir(lista[_seleccionado]);
  }

  void _cambiarFiltro(_Tipo? tipo) {
    setState(() {
      _filtro = tipo;
      _seleccionado = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 820, maxHeight: alto * 0.88),
            child: Material(
              color: Colors.white,
              elevation: 20,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () => _mover(1),
                  const SingleActivator(LogicalKeyboardKey.arrowUp): () => _mover(-1),
                  const SingleActivator(LogicalKeyboardKey.enter): _abrirSeleccionado,
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      Navigator.of(context).pop(),
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón 'x' sutil en la esquina superior derecha
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 14),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                          splashRadius: 18,
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),

                    // Barra superior con input ovalado y botón 'Cancelar'
                    _buildTopSearchBar(),

                    const SizedBox(height: 14),

                    // Píldoras de filtro por categoría
                    if (!_cargando && !_error) _buildFiltros(),

                    // Aviso si alguna tabla no se pudo cargar
                    if (!_cargando && !_error && _fallidos.isNotEmpty)
                      _buildAvisoParcial(),

                    const SizedBox(height: 8),

                    // Lista de tarjetas de resultados
                    Flexible(child: _buildCuerpo()),

                    // Barra de estado y atajos inferior
                    _buildPie(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Campo de búsqueda estilo cápsula con borde verde suave
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFD1E4DA),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF0F3E29),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      cursorColor: const Color(0xFF0F3E29),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Buscar lugares, actividades, gastronomía...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => _controller.clear(),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Botón Cancelar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              foregroundColor: const Color(0xFF0F3E29),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF0F3E29),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoParcial() {
    final nombres = _fallidos.map((t) => t.etiqueta).join(', ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 18, color: Color(0xFFB45309)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No se pudieron cargar: $nombres.',
                style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _cargarTodo,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final coincidencias = _coincidencias;
    int contar(_Tipo t) => coincidencias.where((r) => r.tipo == t).length;

    Widget pill({
      required String label,
      required int count,
      required bool isSelected,
      IconData? icon,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: isSelected ? const Color(0xFF0F3E29) : const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 14,
                vertical: 9,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF0F3E29),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '$label ($count)',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF0F3E29),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          pill(
            label: 'Todos',
            count: coincidencias.length,
            isSelected: _filtro == null,
            onTap: () => _cambiarFiltro(null),
          ),
          for (final t in _Tipo.values)
            pill(
              label: t.etiqueta,
              count: contar(t),
              isSelected: _filtro == t,
              icon: t.icono,
              onTap: () => _cambiarFiltro(t),
            ),
        ],
      ),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F3E29)),
        ),
      );
    }

    if (_error) {
      return _mensaje(
        Icons.cloud_off_outlined,
        'No se pudo conectar con la base de datos.',
        accion: TextButton.icon(
          onPressed: _cargarTodo,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    final lista = _visibles;
    if (lista.isEmpty) {
      return _mensaje(
        Icons.search_off,
        _query.isEmpty
            ? 'No hay contenido en esta categoría.'
            : 'No se encontraron resultados para "$_query"',
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ItemCard(
        resultado: lista[i],
        query: _query,
        seleccionado: i == _seleccionado,
        onHover: () {
          if (_seleccionado != i) setState(() => _seleccionado = i);
        },
        onTap: () => _abrir(lista[i]),
      ),
    );
  }

  Widget _mensaje(IconData icono, String texto, {Widget? accion}) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            if (accion != null) ...[const SizedBox(height: 8), accion],
          ],
        ),
      ),
    );
  }

  Widget _buildPie() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFB),
        border: Border(top: BorderSide(color: Color(0xFFEEF3EF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Color(0xFF144D34)),
          const SizedBox(width: 6),
          Text(
            '${_visibles.length} resultados',
            style: const TextStyle(
              color: Color(0xFF144D34),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          const _KeyBadge('↑'),
          const SizedBox(width: 3),
          const _KeyBadge('↓'),
          const SizedBox(width: 5),
          const Text(
            'Navegar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          const _KeyBadge('Esc'),
          const SizedBox(width: 5),
          const Text(
            'Cerrar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual idéntica a la maqueta de referencia.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.resultado,
    required this.query,
    required this.seleccionado,
    required this.onHover,
    required this.onTap,
  });

  final _Resultado resultado;
  final String query;
  final bool seleccionado;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: seleccionado ? const Color(0xFFF4F9F6) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionado ? const Color(0xFF86EFAC) : const Color(0xFFE9EFEA),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: seleccionado ? 0.04 : 0.015),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Miniatura con esquinas redondeadas
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 105,
                  height: 75,
                  child: resultado.imagenUrl != null
                      ? Image.network(
                          resultado.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                        )
                      : _buildFallbackThumbnail(),
                ),
              ),
              const SizedBox(width: 14),

              // Contenido central: Título, ubicación, duración/dificultad y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Text(
                      resultado.nombre,
                      style: const TextStyle(
                        color: Color(0xFF0F3E29),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Ubicación (solo si está registrada)
                    if (resultado.ubicacion != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              resultado.ubicacion!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Datos reales del registro: duración, precio, fecha...
                    if (resultado.datos.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < resultado.datos.length; i++) ...[
                            if (i > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Icon(
                              resultado.datos[i].icono,
                              size: 13,
                              color: const Color(0xFF1E7A4D),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              resultado.datos[i].texto,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Lado derecho: Píldora de Categoría y flecha Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge pill de categoría
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F0E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          resultado.badgeIcono,
                          size: 13,
                          color: const Color(0xFF144D34),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          resultado.badgeTexto,
                          style: const TextStyle(
                            color: Color(0xFF144D34),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Flecha Chevron verde
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Color(0xFF144D34),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B4D36),
            const Color(0xFF26674B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          resultado.badgeIcono,
          color: Colors.white.withValues(alpha: 0.8),
          size: 24,
        ),
      ),
    );
  }
}

/// Etiqueta visual para representar una tecla física del teclado (ej. '↑', 'Esc').
class _KeyBadge extends StatelessWidget {
  const _KeyBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
