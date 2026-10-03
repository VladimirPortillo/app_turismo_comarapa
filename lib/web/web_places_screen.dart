import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lugar.dart';
import '../models/turismo_tipo.dart';
import '../repositories/lugar_repository.dart';
import '../screens/places_screen.dart'
    show
        AmboroArchPainter,
        CactusMountainPainter,
        LagunasLeafPainter,
        MiradorSerraniaPainter,
        PrehispanicColumnsPainter;
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_place_detail_screen.dart';
import 'web_widgets.dart';

/// Listado de lugares turísticos para la versión web de escritorio.
class WebPlacesScreen extends StatelessWidget {
  const WebPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<Lugar>(
      antetitulo: 'Descubre la belleza de',
      lema: 'Naturaleza, cultura y tradición en un solo lugar',
      hint: 'Buscar un lugar...',
      singular: 'lugar encontrado',
      plural: 'lugares encontrados',
      iconoVacio: Icons.search_off_outlined,
      cargar: (context) => context.read<LugarRepository>().fetchActivos(),
      categoria: (l) => l.categoriaNombre,
      iconoCategoria: iconoCategoriaLugar,
      imagenes: (l) => l.imagenes,
      textoBusqueda: (l) => '${l.nombre} ${l.descripcion}',
      filtros: [
        CatFiltro<Lugar>(
          titulo: 'Dificultad',
          icono: Icons.signal_cellular_alt,
          opciones: (_) => [
            for (final nivel in kNivelesDificultad)
              CatOpcion(dificultadLabel(nivel), (l) => l.dificultad == nivel),
          ],
        ),
      ],
      tarjeta: (l) => CatTarjeta(
        titulo: l.nombre,
        imagenes: l.imagenes,
        respaldo: painterParaLugar(l.nombre),
        categoria: textoONulo(l.categoriaNombre),
        datos: [
          if ((l.tiempoVisitaMin ?? 0) > 0)
            CatDato(Icons.access_time, duracionLabel(l.tiempoVisitaMin)),
          CatDato(Icons.terrain_outlined, dificultadLabel(l.dificultad)),
        ],
        descripcion: l.descripcion,
        abrirDetalle: (_) => WebPlaceDetailScreen(lugar: l),
      ),
    );
  }
}

/// Ícono según el nombre de la categoría del lugar.
IconData iconoCategoriaLugar(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('mirador')) return Icons.landscape_outlined;
  if (c.contains('natur')) return Icons.eco_outlined;
  if (c.contains('laguna') || c.contains('río') || c.contains('rio') ||
      c.contains('agua') || c.contains('cascada')) {
    return Icons.water_outlined;
  }
  if (c.contains('hist') || c.contains('arqueo') || c.contains('ruina')) {
    return Icons.account_balance_outlined;
  }
  if (c.contains('cultur') || c.contains('relig') || c.contains('iglesia')) {
    return Icons.church_outlined;
  }
  if (c.contains('parque') || c.contains('plaza')) return Icons.park_outlined;
  return Icons.place_outlined;
}

/// Ilustración de respaldo cuando el lugar no tiene foto
/// (mismos dibujos que usa la app móvil).
CustomPainter painterParaLugar(String nombre) {
  final name = nombre.toLowerCase();
  if (name.contains('cactus')) return CactusMountainPainter();
  if (name.contains('laguna')) return LagunasLeafPainter();
  if (name.contains('ruina') || name.contains('fuerte') || name.contains('plaza')) {
    return PrehispanicColumnsPainter();
  }
  if (name.contains('puerta') || name.contains('amboró') || name.contains('ave')) {
    return AmboroArchPainter();
  }
  return MiradorSerraniaPainter();
}

/// Tarjeta compacta de lugar, usada en la página de inicio web.
class WebLugarCard extends StatelessWidget {
  const WebLugarCard({super.key, required this.lugar});

  final Lugar lugar;

  @override
  Widget build(BuildContext context) {
    return WebEntityCard(
      imagenes: lugar.imagenes,
      respaldo: painterParaLugar(lugar.nombre),
      titulo: lugar.nombre,
      badges: [WebBadge(texto: lugar.categoriaNombre ?? 'Sin categoría')],
      meta: [
        WebMeta(
          icono: Icons.access_time_outlined,
          texto: duracionLabel(lugar.tiempoVisitaMin),
        ),
        WebMeta(
          icono: Icons.terrain_outlined,
          texto: dificultadLabel(lugar.dificultad),
        ),
      ],
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WebPlaceDetailScreen(lugar: lugar)),
        );
      },
    );
  }
}
