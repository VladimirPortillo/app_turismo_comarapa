import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurante.dart';
import '../repositories/restaurante_repository.dart';
import '../screens/restaurants_screen.dart'
    show
        CoffeeBakeryPainter,
        GrillBarbecuePainter,
        PizzaPastaPainter,
        RestaurantDefaultPainter,
        TraditionalEateryPainter;
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_restaurant_detail_screen.dart';

/// Listado de restaurantes para la versión web de escritorio.
class WebRestaurantsScreen extends StatelessWidget {
  const WebRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<Restaurante>(
      antetitulo: 'Disfruta la cocina de',
      lema: 'Comida típica, parrillas, cafés y mucho más',
      hint: 'Buscar restaurantes, parrillas, cafés...',
      singular: 'restaurante encontrado',
      plural: 'restaurantes encontrados',
      iconoVacio: Icons.no_meals_outlined,
      cargar: (context) => context.read<RestauranteRepository>().fetchActivos(),
      categoria: (r) => r.categoriaNombre,
      iconoCategoria: iconoCategoriaRestaurante,
      imagenes: (r) => r.imagenes,
      textoBusqueda: (r) =>
          '${r.nombre} ${r.descripcion} ${r.direccionReferencia ?? ''}',
      filtros: [
        CatFiltro<Restaurante>(
          titulo: 'Reservas',
          icono: Icons.phone_in_talk_outlined,
          opciones: (_) => [
            CatOpcion('Con contacto', (r) => textoONulo(r.contacto) != null),
          ],
        ),
        CatFiltro<Restaurante>(
          titulo: 'Calificación',
          icono: Icons.star_outline,
          opciones: (_) => [
            CatOpcion('4+ ★', (r) => r.calificacionPromedio >= 4),
            CatOpcion('3+ ★', (r) => r.calificacionPromedio >= 3),
          ],
        ),
      ],
      tarjeta: (r) {
        final horario = textoONulo(r.horarioAtencion);
        final direccion = textoONulo(r.direccionReferencia);
        final precio = r.precioReferencial;
        return CatTarjeta(
          titulo: r.nombre,
          imagenes: r.imagenes,
          respaldo: painterParaRestaurante(r.categoriaNombre ?? '', r.nombre),
          categoria: textoONulo(r.categoriaNombre),
          iconoTitulo: Icons.storefront,
          etiqueta: r.calificacionPromedio > 0
              ? '★ ${r.calificacionPromedio.toStringAsFixed(1)}'
              : null,
          datos: [
            if (horario != null) CatDato(Icons.access_time, horario),
            if (precio != null && precio > 0)
              CatDato(Icons.payments_outlined, 'Bs ${precio.toInt()} ref.'),
            if (direccion != null) CatDato(Icons.place_outlined, direccion),
          ],
          descripcion: r.descripcion,
          abrirDetalle: (_) => WebRestaurantDetailScreen(restaurante: r),
        );
      },
    );
  }
}

/// Ícono según el tipo de cocina.
IconData iconoCategoriaRestaurante(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('café') || c.contains('cafe') || c.contains('reposter')) {
    return Icons.local_cafe_outlined;
  }
  if (c.contains('parrilla') || c.contains('asado')) {
    return Icons.outdoor_grill_outlined;
  }
  if (c.contains('pizza') || c.contains('rápida') || c.contains('rapida')) {
    return Icons.local_pizza_outlined;
  }
  if (c.contains('típica') || c.contains('tipica') || c.contains('tradic')) {
    return Icons.soup_kitchen_outlined;
  }
  return Icons.restaurant_outlined;
}

/// Ilustración de respaldo (mismos dibujos que la app móvil).
CustomPainter painterParaRestaurante(String categoria, String nombre) {
  final cat = categoria.toLowerCase();
  final name = nombre.toLowerCase();
  if (cat.contains('café') || cat.contains('repostería') || name.contains('durazno')) {
    return CoffeeBakeryPainter();
  }
  if (cat.contains('parrilla') || name.contains('asador') || name.contains('chaqueño')) {
    return GrillBarbecuePainter();
  }
  if (cat.contains('pizza') || name.contains('beto')) return PizzaPastaPainter();
  if (cat.contains('típica') || cat.contains('tipica') || name.contains('fogón')) {
    return TraditionalEateryPainter();
  }
  return RestaurantDefaultPainter();
}
