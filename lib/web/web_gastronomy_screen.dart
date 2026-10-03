import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../repositories/gastronomia_repository.dart';
import '../screens/gastronomy_screen.dart'
    show
        ArtisanalLiquorPainter,
        BakeryPastryPainter,
        PeachDessertPainter,
        TraditionalDishPainter;
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_gastronomy_detail_screen.dart';

/// Listado de gastronomía típica para la versión web de escritorio.
class WebGastronomyScreen extends StatelessWidget {
  const WebGastronomyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<GastronomiaItem>(
      antetitulo: 'Los sabores de',
      lema: 'Platos típicos, dulces de durazno, panes y licores artesanales',
      hint: 'Buscar platos, postres, licores...',
      singular: 'plato encontrado',
      plural: 'platos encontrados',
      iconoVacio: Icons.no_food_outlined,
      cargar: (context) => context.read<GastronomiaRepository>().fetchActivos(),
      categoria: (g) => g.categoriaNombre,
      iconoCategoria: iconoCategoriaGastronomia,
      imagenes: (g) => g.imagenes,
      textoBusqueda: (g) =>
          '${g.nombre} ${g.descripcion} ${g.restauranteNombre ?? ''}',
      filtros: [
        CatFiltro<GastronomiaItem>(
          titulo: 'Dónde probarlo',
          icono: Icons.restaurant_outlined,
          opciones: (_) => [
            CatOpcion(
              'Con restaurante',
              (g) =>
                  g.restauranteId != null ||
                  textoONulo(g.restauranteNombre) != null,
            ),
          ],
        ),
        CatFiltro<GastronomiaItem>(
          titulo: 'Temporada',
          icono: Icons.event,
          opciones: (items) {
            final temporadas = <String>{
              for (final g in items)
                if (textoONulo(g.temporada) != null) g.temporada!.trim(),
            }.toList()
              ..sort();
            return [
              for (final t in temporadas)
                CatOpcion(t, (g) => g.temporada?.trim() == t),
            ];
          },
        ),
      ],
      tarjeta: (g) {
        final precio = precioBs(g.precioReferencial);
        final restaurante = textoONulo(g.restauranteNombre);
        final temporada = textoONulo(g.temporada);
        return CatTarjeta(
          titulo: g.nombre,
          imagenes: g.imagenes,
          respaldo: painterParaGastronomia(g.nombre),
          categoria: textoONulo(g.categoriaNombre),
          iconoTitulo: Icons.restaurant_menu,
          etiqueta: precio.isEmpty ? null : precio,
          datos: [
            if (restaurante != null)
              CatDato(Icons.storefront_outlined, restaurante),
            if (temporada != null) CatDato(Icons.event, temporada),
          ],
          descripcion: g.descripcion,
          abrirDetalle: (_) => WebGastronomyDetailScreen(item: g),
        );
      },
    );
  }
}

/// Ícono según el nombre de la categoría gastronómica.
IconData iconoCategoriaGastronomia(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('bebida') || c.contains('licor') || c.contains('vino')) {
    return Icons.local_bar_outlined;
  }
  if (c.contains('postre') || c.contains('dulce')) return Icons.icecream_outlined;
  if (c.contains('pan') || c.contains('masa') || c.contains('reposter')) {
    return Icons.bakery_dining_outlined;
  }
  if (c.contains('fruta') || c.contains('durazno')) return Icons.spa_outlined;
  return Icons.restaurant_menu_outlined;
}

/// Ilustración de respaldo (mismos dibujos que la app móvil).
CustomPainter painterParaGastronomia(String nombre) {
  final name = nombre.toLowerCase();
  if (name.contains('picante') || name.contains('pique') || name.contains('sopa')) {
    return TraditionalDishPainter();
  }
  if (name.contains('mermelada') || name.contains('dulce') || name.contains('durazno')) {
    return PeachDessertPainter();
  }
  if (name.contains('licor') || name.contains('bebida')) {
    return ArtisanalLiquorPainter();
  }
  return BakeryPastryPainter();
}
