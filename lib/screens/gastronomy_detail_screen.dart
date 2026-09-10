import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../models/restaurante.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/restaurante_repository.dart';
import '../widgets/fullscreen_image_gallery.dart';
import '../widgets/resenas_section.dart';

class GastronomyDetailScreen extends StatefulWidget {
  final GastronomiaItem item;

  const GastronomyDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<GastronomyDetailScreen> createState() => _GastronomyDetailScreenState();
}

class _GastronomyDetailScreenState extends State<GastronomyDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  double _promedioResenas = 0;
  int _totalResenas = 0;

  Restaurante? _restauranteVinculado;
  List<String> _restaurantesRelacionadosNombres = <String>[];
  bool _cargandoRestaurantesRelacionados = false;

  bool get _esCategoriaComida {
    final cat = widget.item.categoriaNombre?.trim().toLowerCase() ?? '';
    if (cat.isEmpty) return false;
    return cat.contains('comid') || cat.contains('plato');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final restauranteId = widget.item.restauranteId;
    if (restauranteId != null) {
      _cargarRestauranteVinculado(restauranteId);
    }
    if (_esCategoriaComida) {
      _cargarRestaurantesRelacionados();
    }
  }

  Future<void> _cargarRestauranteVinculado(String restauranteId) async {
    try {
      final repo = context.read<RestauranteRepository>();
      final restaurante = await repo.fetchById(restauranteId);
      if (!mounted) return;
      setState(() {
        _restauranteVinculado = restaurante;
        if (restaurante != null &&
            !_restaurantesRelacionadosNombres.contains(restaurante.nombre.trim())) {
          _restaurantesRelacionadosNombres.add(restaurante.nombre.trim());
          _restaurantesRelacionadosNombres.sort();
        }
      });
    } catch (_) {}
  }

  Future<void> _cargarRestaurantesRelacionados() async {
    setState(() => _cargandoRestaurantesRelacionados = true);
    final nombresEncontrados = <String>{};

    try {
      // 1. Restaurante vinculado directo o registrado en el item
      if (_restauranteVinculado != null) {
        nombresEncontrados.add(_restauranteVinculado!.nombre.trim());
      } else if (widget.item.restauranteNombre != null &&
          widget.item.restauranteNombre!.trim().isNotEmpty) {
        nombresEncontrados.add(widget.item.restauranteNombre!.trim());
      }

      // 2. Buscar en restaurantes activos
      final restauranteRepo = context.read<RestauranteRepository>();
      final restaurantes = await restauranteRepo.fetchActivos();

      final nombrePlato = widget.item.nombre.trim().toLowerCase();

      const stopWords = {
        'para', 'como', 'todo', 'toda', 'este', 'esta', 'estos', 'estas',
        'comarapa', 'comarapeño', 'comarapeña', 'estilo', 'sabor',
        'tradicional', 'tipico', 'tipica', 'plato', 'platos'
      };
      final palabrasClave = nombrePlato
          .split(RegExp(r'\s+'))
          .map((w) => w.replaceAll(RegExp(r'[^\wáéíóúñ]'), '').trim())
          .where((w) => w.length >= 4 && !stopWords.contains(w))
          .toList();

      for (final r in restaurantes) {
        if (widget.item.restauranteId != null && r.id == widget.item.restauranteId) {
          nombresEncontrados.add(r.nombre.trim());
          continue;
        }

        final desc = r.descripcion.toLowerCase();
        final rNom = r.nombre.toLowerCase();

        if (desc.contains(nombrePlato) || rNom.contains(nombrePlato)) {
          nombresEncontrados.add(r.nombre.trim());
          continue;
        }

        if (palabrasClave.isNotEmpty) {
          final coincidePalabra = palabrasClave.any(
            (p) => desc.contains(p) || rNom.contains(p),
          );
          if (coincidePalabra) {
            nombresEncontrados.add(r.nombre.trim());
          }
        }
      }

      // 3. Buscar en la tabla gastronomía otros platos con el mismo nombre vinculados a restaurantes
      final gastroRepo = context.read<GastronomiaRepository>();
      final otrosPlatos = await gastroRepo.fetchActivos();

      for (final p in otrosPlatos) {
        final pNom = p.nombre.trim().toLowerCase();
        final esMismoPlato = pNom == nombrePlato ||
            pNom.contains(nombrePlato) ||
            nombrePlato.contains(pNom);

        if (esMismoPlato) {
          if (p.restauranteNombre != null && p.restauranteNombre!.trim().isNotEmpty) {
            nombresEncontrados.add(p.restauranteNombre!.trim());
          } else if (p.restauranteId != null) {
            final match = restaurantes.where((r) => r.id == p.restauranteId).firstOrNull;
            if (match != null) {
              nombresEncontrados.add(match.nombre.trim());
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _restaurantesRelacionadosNombres = nombresEncontrados.toList()..sort();
        _cargandoRestaurantesRelacionados = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restaurantesRelacionadosNombres = nombresEncontrados.toList()..sort();
        _cargandoRestaurantesRelacionados = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _categoriaLabel {
    final cat = widget.item.categoriaNombre;
    if (cat != null && cat.trim().isNotEmpty) {
      return cat.toUpperCase();
    }
    return 'GASTRONOMÍA';
  }

  String get _precioTexto {
    final p = widget.item.precioReferencial;
    if (p != null && p > 0) {
      return 'Bs ${p.toInt()}';
    }
    if (p == 0) return 'Gratis';
    return '';
  }

  String get _temporadaTexto {
    final t = widget.item.temporada;
    if (t != null && t.trim().isNotEmpty) {
      return t.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.item.imagenes;
    final totalSlides = imagenes.isNotEmpty ? imagenes.length : 3;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Stack(
        children: [
          // Contenido principal scrolleable
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con carrusel/ilustración
                _buildHeroHeader(totalSlides),

                // Tarjeta de información con bordes superiores redondeados
                _buildContentCard(),
              ],
            ),
          ),

          // Botón fijo inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(int totalSlides) {
    final imagenes = widget.item.imagenes;

    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carrusel de imágenes o ilustración vectorial
          if (imagenes.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: imagenes.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final url = imagenes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => FullscreenImageGallery(
                          imagenes: imagenes,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIllustration(),
                  ),
                );
              },
            )
          else
            PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _buildFallbackIllustration(),
            ),

          // Indicador de página animado
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSlides, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Barra superior con botones circulares
          // Barra superior de navegación con botón volver
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Botón Volver
                  _buildCircleButton(
                    icon: Icons.chevron_left,
                    iconSize: 26,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8C4717),
            Color(0xFFB45309),
            Color(0xFFD97706),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.item.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 24,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    final tieneDescripcion = widget.item.descripcion.trim().isNotEmpty;
    final tieneRestaurante = _restauranteVinculado != null;

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF9F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFBECE2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _categoriaLabel,
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del Plato
            Text(
              widget.item.nombre,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Puntuación y Reseñas
            Row(
              children: [
                ...List.generate(5, (i) {
                  final activo = i < _promedioResenas.round();
                  return Icon(
                    activo ? Icons.star : Icons.star_border,
                    size: 20,
                    color: const Color(0xFFE59819),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _totalResenas == 0
                      ? 'Sin reseñas todavía'
                      : '${_promedioResenas.toStringAsFixed(1)} · $_totalResenas ${_totalResenas == 1 ? "reseña" : "reseñas"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fila de tarjetas de información rápida (solo con datos de la BD)
            _buildQuickInfoGrid(),
            const SizedBox(height: 28),

            // Sección: Descripción (solo si está registrada en la BD)
            if (tieneDescripcion) ...[
              const Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143525),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.descripcion.trim(),
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Sección: Dónde degustarlo (solo si tiene restaurante vinculado en la BD)
            if (tieneRestaurante) ...[
              _buildDondeDegustarCard(),
              const SizedBox(height: 28),
            ],

            // Sección: Reseñas (guardadas en la BD)
            if (widget.item.id != null)
              ResenasSection(
                entidad: 'gastronomia',
                entidadId: widget.item.id!,
                onResumenActualizado: (promedio, total) {
                  setState(() {
                    _promedioResenas = promedio;
                    _totalResenas = total;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoGrid() {
    final items = <Widget>[];

    // 1. Categoría (registrada en la BD)
    if (widget.item.categoriaNombre != null && widget.item.categoriaNombre!.trim().isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.category_outlined,
        title: 'CATEGORÍA',
        value: widget.item.categoriaNombre!.trim(),
      ));
    }

    // 2. Precio referencial (solo si está registrado en la BD)
    if (_precioTexto.isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.payments_outlined,
        title: 'PRECIO REF.',
        value: _precioTexto,
        valueColor: const Color(0xFFB45309),
      ));
    }

    // 3. Temporada (columna real en la BD)
    if (_temporadaTexto.isNotEmpty) {
      items.add(_buildInfoItem(
        icon: Icons.calendar_today_outlined,
        title: 'TEMPORADA',
        value: _temporadaTexto,
      ));
    }

    // 4. Restaurante asignado en la BD
    if (_restauranteVinculado != null) {
      items.add(_buildInfoItem(
        icon: Icons.restaurant_outlined,
        title: 'RESTAURANTE',
        value: _restauranteVinculado!.nombre,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: items[i]),
        ],
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB45309)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDondeDegustarCard() {
    if (_restauranteVinculado == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFBECE2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Color(0xFFB45309),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DÓNDE DEGUSTARLO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _restauranteVinculado!.nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_restauranteVinculado!.direccionReferencia?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    _restauranteVinculado!.direccionReferencia!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalRestaurantes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurantes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF143525),
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lugares donde degustar ${widget.item.nombre}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (_cargandoRestaurantesRelacionados)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_restaurantesRelacionadosNombres.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No hay restaurantes registrados que ofrezcan este plato actualmente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _restaurantesRelacionadosNombres.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final nombre = _restaurantesRelacionadosNombres[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBECE2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Color(0xFFB45309),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final tienePrecio = widget.item.precioReferencial != null &&
        widget.item.precioReferencial! > 0;
    final esComida = _esCategoriaComida;

    if (!tienePrecio && !esComida) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Precio referencial (si existe en la BD)
            if (tienePrecio) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PRECIO REFERENCIAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _precioTexto,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF143525),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ porción',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (esComida) const SizedBox(width: 16),
            ],

            // Botón "Ver restaurantes" (SOLO aparece si la categoría es comida)
            if (esComida)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarModalRestaurantes(context),
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text(
                      'Ver restaurantes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26674B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
