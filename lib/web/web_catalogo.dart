import 'package:flutter/material.dart';

import '../screens/home_screen.dart' show BannerBackgroundPainter;
import 'web_widgets.dart' show WebMensaje;

// Diseño común de las secciones web (Lugares, Actividades, Gastronomía,
// Hoteles, Restaurantes y Eventos): portada con buscador, filtros a la
// izquierda y resultados en cuadrícula o lista.

const Color kCatVerdeOscuro = Color(0xFF0F4D32);
const Color kCatVerdeBoton = Color(0xFF1E8E5A);
const Color _verdeSuave = Color(0xFFE6F2EB);
const Color _textoGris = Color(0xFF6B7280);

/// Dato corto de una tarjeta (duración, precio, fecha...).
class CatDato {
  const CatDato(this.icono, this.texto, {this.color});

  final IconData icono;
  final String texto;
  final Color? color;
}

/// Lo que muestra una tarjeta del catálogo.
class CatTarjeta {
  const CatTarjeta({
    required this.titulo,
    required this.imagenes,
    required this.respaldo,
    required this.abrirDetalle,
    this.categoria,
    this.iconoTitulo = Icons.location_on,
    this.datos = const <CatDato>[],
    this.descripcion = '',
    this.etiqueta,
    this.atenuada = false,
  });

  final String titulo;
  final List<String> imagenes;

  /// Dibujo que se muestra si no hay foto.
  final CustomPainter respaldo;
  final WidgetBuilder abrirDetalle;
  final String? categoria;
  final IconData iconoTitulo;
  final List<CatDato> datos;
  final String descripcion;

  /// Chip blanco arriba a la derecha de la foto (precio, fecha, ★ 4.5...).
  final String? etiqueta;

  /// Se muestra más tenue (ej. eventos finalizados).
  final bool atenuada;
}

/// Opción de un grupo de filtros en forma de píldora.
class CatOpcion<T> {
  const CatOpcion(this.label, this.cumple);

  final String label;
  final bool Function(T item) cumple;
}

/// Grupo de filtros en forma de píldora (Dificultad, Precio, Mes...).
class CatFiltro<T> {
  const CatFiltro({
    required this.titulo,
    required this.icono,
    required this.opciones,
    this.multiple = false,
  });

  final String titulo;
  final IconData icono;

  /// Las opciones se calculan con los datos cargados.
  final List<CatOpcion<T>> Function(List<T> items) opciones;

  /// true: se pueden marcar varias y el elemento debe cumplir todas.
  final bool multiple;
}

/// Pantalla de catálogo reutilizable.
class WebCatalogo<T> extends StatefulWidget {
  const WebCatalogo({
    super.key,
    required this.antetitulo,
    required this.lema,
    required this.hint,
    required this.cargar,
    required this.tarjeta,
    required this.categoria,
    required this.iconoCategoria,
    required this.imagenes,
    required this.textoBusqueda,
    required this.singular,
    required this.plural,
    required this.iconoVacio,
    this.titulo = 'Comarapa',
    this.filtros = const [],
    this.orden,
    this.altoTarjeta = 440,
  });

  /// Texto pequeño sobre el título de la portada ("DESCUBRE LA BELLEZA DE").
  final String antetitulo;
  final String titulo;

  /// Frase bajo el título de la portada.
  final String lema;
  final String hint;

  final Future<List<T>> Function(BuildContext context) cargar;
  final CatTarjeta Function(T item) tarjeta;
  final String? Function(T item) categoria;
  final IconData Function(String categoria) iconoCategoria;
  final List<String> Function(T item) imagenes;

  /// Texto en el que busca el buscador (nombre, descripción...).
  final String Function(T item) textoBusqueda;

  final List<CatFiltro<T>> filtros;
  final int Function(T a, T b)? orden;

  /// "lugar encontrado" / "lugares encontrados".
  final String singular;
  final String plural;
  final IconData iconoVacio;
  final double altoTarjeta;

  @override
  State<WebCatalogo<T>> createState() => _WebCatalogoState<T>();
}

class _WebCatalogoState<T> extends State<WebCatalogo<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _categoria;
  bool _vistaLista = false;
  bool _loading = true;
  String? _error;
  List<T> _items = <T>[];

  /// Opciones marcadas por grupo de filtros (índice del grupo -> labels).
  final Map<int, Set<String>> _marcadas = <int, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
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
      final items = await widget.cargar(context);
      if (widget.orden != null) items.sort(widget.orden);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<T> get _filtrados {
    final opcionesPorGrupo = [
      for (final f in widget.filtros) f.opciones(_items),
    ];
    return _items.where((item) {
      if (_categoria != null && widget.categoria(item)?.trim() != _categoria) {
        return false;
      }
      for (var g = 0; g < widget.filtros.length; g++) {
        final marcadas = _marcadas[g];
        if (marcadas == null || marcadas.isEmpty) continue;
        for (final opcion in opcionesPorGrupo[g]) {
          if (marcadas.contains(opcion.label) && !opcion.cumple(item)) {
            return false;
          }
        }
      }
      return _query.isEmpty ||
          widget.textoBusqueda(item).toLowerCase().contains(_query) ||
          (widget.categoria(item) ?? '').toLowerCase().contains(_query);
    }).toList();
  }

  String? get _fotoPortada {
    for (final item in _items) {
      final imgs = widget.imagenes(item);
      if (imgs.isNotEmpty) return imgs.first;
    }
    return null;
  }

  bool get _hayFiltros =>
      _categoria != null ||
      _query.isNotEmpty ||
      _marcadas.values.any((s) => s.isNotEmpty);

  void _limpiar() {
    _searchController.clear();
    setState(() {
      _categoria = null;
      _marcadas.clear();
    });
  }

  void _alternar(int grupo, String label) {
    setState(() {
      final set = _marcadas.putIfAbsent(grupo, () => <String>{});
      if (set.contains(label)) {
        set.remove(label);
      } else {
        if (!widget.filtros[grupo].multiple) set.clear();
        set.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F8F6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPortada(),
            const SizedBox(height: 28),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 330, child: _buildFiltros()),
                      const SizedBox(width: 32),
                      Expanded(child: _buildResultados()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Portada

  Widget _buildPortada() {
    final foto = _fotoPortada;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (foto != null)
              Image.network(
                foto,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    CustomPaint(painter: BannerBackgroundPainter()),
              )
            else
              CustomPaint(painter: BannerBackgroundPainter()),
            // Oscurece el lado izquierdo para que el texto se lea bien.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xB3000000),
                    Color(0x33000000),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 84),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.antetitulo.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          widget.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 62,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          widget.lema,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 68,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kCatVerdeBoton,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 430, child: _buildBuscador()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      height: 62,
      padding: const EdgeInsets.only(left: 22, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF374151), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Borrar',
              onPressed: _searchController.clear,
              icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
            ),
          Material(
            color: kCatVerdeBoton,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => FocusScope.of(context).unfocus(),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.search, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Filtros

  Widget _buildFiltros() {
    final conteo = <String, int>{};
    for (final item in _items) {
      final c = widget.categoria(item)?.trim();
      if (c != null && c.isNotEmpty) conteo[c] = (conteo[c] ?? 0) + 1;
    }
    final categorias = conteo.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloFiltro(Icons.filter_alt_outlined, 'Categoría'),
          const SizedBox(height: 12),
          _opcionCategoria(
            icono: Icons.terrain,
            label: 'Todas',
            cantidad: _items.length,
            seleccionada: _categoria == null,
            onTap: () => setState(() => _categoria = null),
          ),
          for (final c in categorias)
            _opcionCategoria(
              icono: widget.iconoCategoria(c),
              label: c,
              cantidad: conteo[c]!,
              seleccionada: _categoria == c,
              onTap: () => setState(() => _categoria = c),
            ),
          for (var g = 0; g < widget.filtros.length; g++)
            ..._buildGrupo(g),
          if (_hayFiltros) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(foregroundColor: kCatVerdeOscuro),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: CustomPaint(painter: _MontanasDecorativasPainter()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGrupo(int g) {
    final filtro = widget.filtros[g];
    final opciones = filtro.opciones(_items);
    if (opciones.isEmpty) return const <Widget>[];
    final marcadas = _marcadas[g] ?? const <String>{};

    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(height: 1),
      ),
      _tituloFiltro(filtro.icono, filtro.titulo),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final o in opciones)
            _pildora(o.label, marcadas.contains(o.label), () => _alternar(g, o.label)),
        ],
      ),
    ];
  }

  Widget _tituloFiltro(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icono, color: kCatVerdeOscuro, size: 22),
          const SizedBox(width: 10),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kCatVerdeOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcionCategoria({
    required IconData icono,
    required String label,
    required int cantidad,
    required bool seleccionada,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: seleccionada ? _verdeSuave : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icono, color: kCatVerdeOscuro, size: 24),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF1F2937),
                      fontWeight:
                          seleccionada ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (seleccionada)
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kCatVerdeOscuro,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '$cantidad',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
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

  Widget _pildora(String label, bool sel, VoidCallback onTap) {
    return Material(
      color: sel ? kCatVerdeOscuro : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: sel ? kCatVerdeOscuro : const Color(0xFF9CB8A8)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: sel ? Colors.white : kCatVerdeOscuro,
              fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Resultados

  Widget _buildResultados() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(60),
        child: WebMensaje(
          icono: Icons.error_outline,
          titulo: 'No se pudo cargar la información',
          detalle: _error,
          accion: FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      );
    }

    final filtrados = _filtrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: kCatVerdeOscuro, size: 20),
            const SizedBox(width: 8),
            Text(
              '${filtrados.length} '
              '${filtrados.length == 1 ? widget.singular : widget.plural}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            _buildSelectorVista(),
          ],
        ),
        const SizedBox(height: 16),
        if (filtrados.isEmpty)
          Padding(
            padding: const EdgeInsets.all(60),
            child: WebMensaje(
              icono: widget.iconoVacio,
              titulo: _items.isEmpty
                  ? 'Todavía no hay contenido publicado'
                  : 'Sin resultados',
              detalle: _items.isEmpty
                  ? null
                  : 'Prueba con otra categoría, filtro o término de búsqueda.',
              accion: _hayFiltros
                  ? TextButton(
                      onPressed: _limpiar,
                      child: const Text('Limpiar filtros'),
                    )
                  : null,
            ),
          )
        else if (_vistaLista)
          for (final item in filtrados)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                height: 210,
                child: CatTarjetaWidget(
                  datos: widget.tarjeta(item),
                  iconoCategoria: widget.iconoCategoria,
                  horizontal: true,
                ),
              ),
            )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtrados.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisExtent: widget.altoTarjeta,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                ),
                itemBuilder: (context, i) => CatTarjetaWidget(
                  datos: widget.tarjeta(filtrados[i]),
                  iconoCategoria: widget.iconoCategoria,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSelectorVista() {
    Widget boton(IconData icono, bool activo, String tooltip, bool lista) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: activo ? kCatVerdeBoton : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _vistaLista = lista),
            child: SizedBox(
              width: 56,
              height: 38,
              child: Icon(
                icono,
                color: activo ? Colors.white : kCatVerdeOscuro,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          boton(Icons.grid_view_rounded, !_vistaLista, 'Cuadrícula', false),
          boton(Icons.format_list_bulleted, _vistaLista, 'Lista', true),
        ],
      ),
    );
  }
}

// ================================================================ Tarjeta

/// Tarjeta del catálogo: foto con categoría, título, datos, descripción
/// y botón "Ver más". En [horizontal] la foto va a la izquierda.
class CatTarjetaWidget extends StatefulWidget {
  const CatTarjetaWidget({
    super.key,
    required this.datos,
    required this.iconoCategoria,
    this.horizontal = false,
  });

  final CatTarjeta datos;
  final IconData Function(String categoria) iconoCategoria;
  final bool horizontal;

  @override
  State<CatTarjetaWidget> createState() => _CatTarjetaWidgetState();
}

class _CatTarjetaWidgetState extends State<CatTarjetaWidget> {
  bool _hover = false;

  void _abrir() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: widget.datos.abrirDetalle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foto = _buildFoto();
    final contenido = _buildContenido();

    return Opacity(
      opacity: widget.datos.atenuada ? 0.7 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: _abrir,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hover ? 0.12 : 0.05),
                  blurRadius: _hover ? 24 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.horizontal
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 320, child: foto),
                      Expanded(child: contenido),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 220, child: foto),
                      Expanded(child: contenido),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoto() {
    final d = widget.datos;
    final respaldo = CustomPaint(painter: d.respaldo);
    final categoria = d.categoria?.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        d.imagenes.isNotEmpty
            ? Image.network(
                d.imagenes.first,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => respaldo,
              )
            : respaldo,
        if (categoria != null && categoria.isNotEmpty)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kCatVerdeOscuro.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.iconoCategoria(categoria),
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    categoria,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (d.etiqueta != null)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                d.etiqueta!,
                style: const TextStyle(
                  color: kCatVerdeOscuro,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContenido() {
    final d = widget.datos;
    final descripcion = d.descripcion.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(d.iconoTitulo, color: kCatVerdeOscuro, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kCatVerdeOscuro,
                  ),
                ),
              ),
            ],
          ),
          if (d.datos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                for (final dato in d.datos)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(dato.icono, size: 18, color: dato.color ?? _textoGris),
                      const SizedBox(width: 6),
                      Text(
                        dato.texto,
                        style: TextStyle(
                          color: dato.color ?? const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (descripcion.isNotEmpty)
            Expanded(
              child: Text(
                descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoGris,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _abrir,
            style: FilledButton.styleFrom(
              backgroundColor: kCatVerdeOscuro,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver más',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Silueta suave de montañas para el pie del panel de filtros.
class _MontanasDecorativasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.22, h * 0.45)
        ..lineTo(w * 0.38, h * 0.7)
        ..lineTo(w * 0.52, h * 0.1)
        ..lineTo(w * 0.72, h * 0.6)
        ..lineTo(w * 0.85, h * 0.4)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = const Color(0xFFE3EFE7),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.15, h * 0.75)
        ..lineTo(w * 0.32, h * 0.9)
        ..lineTo(w * 0.55, h * 0.55)
        ..lineTo(w * 0.78, h * 0.85)
        ..lineTo(w, h * 0.7)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = const Color(0xFFD2E6D9),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.52, h * 0.1)
        ..lineTo(w * 0.47, h * 0.25)
        ..lineTo(w * 0.52, h * 0.22)
        ..lineTo(w * 0.57, h * 0.27)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
