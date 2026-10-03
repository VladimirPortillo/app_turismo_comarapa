import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../models/restaurante.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/restaurante_repository.dart';
import '../widgets/resenas_section.dart';
import 'web_components.dart';
import 'web_restaurant_detail_screen.dart';
import 'web_theme.dart';
import 'web_widgets.dart';

/// Detalle de un plato / producto típico para la versión web.
class WebGastronomyDetailScreen extends StatefulWidget {
  const WebGastronomyDetailScreen({super.key, required this.item});

  final GastronomiaItem item;

  @override
  State<WebGastronomyDetailScreen> createState() =>
      _WebGastronomyDetailScreenState();
}

class _WebGastronomyDetailScreenState extends State<WebGastronomyDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  bool _cargandoRestaurantes = true;

  /// Restaurantes donde se puede degustar (con datos completos).
  List<Restaurante> _restaurantes = <Restaurante>[];

  /// Nombres registrados que no corresponden a un restaurante activo.
  List<String> _otrosNombres = <String>[];

  GastronomiaItem get _item => widget.item;

  /// Igual que en la app: solo para comidas se buscan otros restaurantes
  /// que puedan ofrecer el mismo plato.
  bool get _esCategoriaComida {
    final cat = _item.categoriaNombre?.trim().toLowerCase() ?? '';
    return cat.contains('comid') || cat.contains('plato');
  }

  @override
  void initState() {
    super.initState();
    _cargarRestaurantes();
  }

  Future<void> _cargarRestaurantes() async {
    final encontrados = <String, Restaurante>{};
    final nombres = <String>{};

    try {
      final restaurantes =
          await context.read<RestauranteRepository>().fetchActivos();
      final gastronomiaRepo = context.read<GastronomiaRepository>();

      // 1. Restaurante vinculado directamente.
      for (final r in restaurantes) {
        if (_item.restauranteId != null && r.id == _item.restauranteId) {
          encontrados[r.nombre.trim()] = r;
        }
      }
      final nombreRegistrado = textoONulo(_item.restauranteNombre);
      if (nombreRegistrado != null) nombres.add(nombreRegistrado);

      if (_esCategoriaComida) {
        // 2. Restaurantes cuya descripción o nombre mencionan el plato.
        final plato = _item.nombre.trim().toLowerCase();
        const stopWords = {
          'para', 'como', 'todo', 'toda', 'este', 'esta', 'estos', 'estas',
          'comarapa', 'comarapeño', 'comarapeña', 'estilo', 'sabor',
          'tradicional', 'tipico', 'tipica', 'plato', 'platos',
        };
        final claves = plato
            .split(RegExp(r'\s+'))
            .map((w) => w.replaceAll(RegExp(r'[^\wáéíóúñ]'), '').trim())
            .where((w) => w.length >= 4 && !stopWords.contains(w))
            .toList();

        for (final r in restaurantes) {
          final desc = r.descripcion.toLowerCase();
          final nom = r.nombre.toLowerCase();
          final coincide = desc.contains(plato) ||
              nom.contains(plato) ||
              claves.any((p) => desc.contains(p) || nom.contains(p));
          if (coincide) encontrados[r.nombre.trim()] = r;
        }

        // 3. Otros registros del mismo plato vinculados a restaurantes.
        final otrosPlatos = await gastronomiaRepo.fetchActivos();
        for (final p in otrosPlatos) {
          final pNom = p.nombre.trim().toLowerCase();
          final mismoPlato =
              pNom == plato || pNom.contains(plato) || plato.contains(pNom);
          if (!mismoPlato) continue;
          final match =
              restaurantes.where((r) => r.id == p.restauranteId).firstOrNull;
          if (match != null) {
            encontrados[match.nombre.trim()] = match;
          } else if (textoONulo(p.restauranteNombre) != null) {
            nombres.add(p.restauranteNombre!.trim());
          }
        }
      }
    } catch (_) {
      // Si falla, se muestra lo que se haya encontrado.
    }

    if (!mounted) return;
    setState(() {
      _restaurantes = encontrados.values.toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      _otrosNombres = nombres
          .where((n) => !encontrados.containsKey(n))
          .toList()
        ..sort();
      _cargandoRestaurantes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final temporada = textoONulo(_item.temporada);

    return WebDetailScaffold(
      seccion: 'Gastronomía',
      titulo: _item.nombre,
      encabezado: WebDetailHeader(
        categoria: textoONulo(_item.categoriaNombre) ?? 'Gastronomía',
        nombre: _item.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          if (temporada != null)
            WebIconText(icono: Icons.calendar_today_outlined, texto: temporada),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _item.imagenes,
        respaldo: const WebIconoRespaldo(icono: Icons.restaurant, calido: true),
        ancho: ancho,
      ),
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebDescripcion(
            titulo: 'Descripción',
            texto: _item.descripcion,
            vacio: 'Este plato todavía no tiene descripción.',
          ),
          if (_item.id != null)
            ResenasSection(
              entidad: 'gastronomia',
              entidadId: _item.id!,
              onResumenActualizado: (promedio, total) {
                setState(() {
                  _promedioResenas = promedio;
                  _totalResenas = total;
                });
              },
            ),
        ],
      ),
      lateral: _buildLateral(temporada),
    );
  }

  Widget _buildLateral(String? temporada) {
    final precio = precioBs(_item.precioReferencial);

    return Column(
      children: [
        WebReservaCard(
          etiquetaPrecio: 'Precio referencial',
          precio: precio,
          rolContacto: '',
          nombreContacto: null,
          iconoContacto: Icons.restaurant,
          textoBoton: '',
          onContactar: null,
        ),
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Detalles'),
              const SizedBox(height: 16),
              WebDato(
                icono: Icons.category_outlined,
                titulo: 'Categoría',
                valor: textoONulo(_item.categoriaNombre) ?? 'Gastronomía',
              ),
              if (precio.isNotEmpty)
                WebDato(
                  icono: Icons.payments_outlined,
                  titulo: 'Precio',
                  valor: precio,
                ),
              if (temporada != null)
                WebDato(
                  icono: Icons.calendar_today_outlined,
                  titulo: 'Temporada',
                  valor: temporada,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildDondeDegustar(),
      ],
    );
  }

  Widget _buildDondeDegustar() {
    return WebTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebCardTitle('Dónde degustarlo'),
          const SizedBox(height: 12),
          if (_cargandoRestaurantes)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_restaurantes.isEmpty && _otrosNombres.isEmpty)
            Text(
              'Todavía no hay restaurantes registrados para este plato.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else ...[
            for (final r in _restaurantes)
              _filaRestaurante(
                r.nombre,
                textoONulo(r.direccionReferencia),
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WebRestaurantDetailScreen(restaurante: r),
                  ),
                ),
              ),
            for (final nombre in _otrosNombres) _filaRestaurante(nombre, null, null),
          ],
        ],
      ),
    );
  }

  Widget _filaRestaurante(String nombre, String? detalle, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBECE2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFFB45309),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (detalle != null)
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: WebTheme.verde),
            ],
          ),
        ),
      ),
    );
  }
}
