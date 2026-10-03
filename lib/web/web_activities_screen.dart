import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/actividad.dart';
import '../models/turismo_tipo.dart';
import '../repositories/actividad_repository.dart';
import '../screens/activities_screen.dart'
    show
        BikeAdventurePainter,
        CulturalTraditionPainter,
        ForestCanopyPainter,
        HorseValleyPainter,
        TrailHikerPainter;
import 'web_activity_detail_screen.dart';
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_widgets.dart';

/// Listado de actividades para la versión web de escritorio.
class WebActivitiesScreen extends StatelessWidget {
  const WebActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<Actividad>(
      antetitulo: 'Vive la aventura en',
      lema: 'Trekking, cabalgatas, ecoturismo y experiencias culturales',
      hint: 'Buscar actividades, trekking, aventura...',
      singular: 'actividad encontrada',
      plural: 'actividades encontradas',
      iconoVacio: Icons.explore_off_outlined,
      cargar: (context) => context.read<ActividadRepository>().fetchActivos(),
      categoria: (a) => a.categoriaNombre,
      iconoCategoria: iconoCategoriaActividad,
      imagenes: (a) => a.imagenes,
      textoBusqueda: (a) => '${a.nombre} ${a.descripcion}',
      filtros: [
        CatFiltro<Actividad>(
          titulo: 'Dificultad',
          icono: Icons.signal_cellular_alt,
          opciones: (_) => [
            for (final nivel in kNivelesDificultad)
              CatOpcion(
                dificultadLabel(nivel),
                (a) => nivelDificultad(a.dificultad) == nivel,
              ),
          ],
        ),
        CatFiltro<Actividad>(
          titulo: 'Precio',
          icono: Icons.payments_outlined,
          opciones: (_) => [
            CatOpcion('Gratis', (a) => (a.precioReferencial ?? 0) <= 0),
            CatOpcion('De pago', (a) => (a.precioReferencial ?? 0) > 0),
          ],
        ),
      ],
      tarjeta: (a) {
        final precio = precioBs(a.precioReferencial);
        final temporada = textoONulo(a.temporada);
        return CatTarjeta(
          titulo: a.nombre,
          imagenes: a.imagenes,
          respaldo: painterParaActividad(a.nombre),
          categoria: textoONulo(a.categoriaNombre),
          iconoTitulo: Icons.hiking,
          etiqueta: precio.isEmpty ? null : precio,
          datos: [
            if ((a.duracionMin ?? 0) > 0)
              CatDato(Icons.access_time, duracionLabel(a.duracionMin)),
            CatDato(
              Icons.terrain_outlined,
              dificultadLabel(nivelDificultad(a.dificultad)),
              color: colorDificultad(a.dificultad),
            ),
            if (temporada != null) CatDato(Icons.event, temporada),
          ],
          descripcion: a.descripcion,
          abrirDetalle: (_) => WebActivityDetailScreen(actividad: a),
        );
      },
    );
  }
}

// ================================================================ Helpers

/// Ícono según el nombre de la categoría de la actividad.
IconData iconoCategoriaActividad(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('trek') || c.contains('sender') || c.contains('camin')) {
    return Icons.hiking;
  }
  if (c.contains('cabalg') || c.contains('caball')) return Icons.pets_outlined;
  if (c.contains('eco') || c.contains('natur') || c.contains('ave')) {
    return Icons.eco_outlined;
  }
  if (c.contains('bici') || c.contains('ciclo')) return Icons.directions_bike;
  if (c.contains('aventura')) return Icons.terrain_outlined;
  if (c.contains('cultur') || c.contains('tradic')) {
    return Icons.theater_comedy_outlined;
  }
  return Icons.explore_outlined;
}

/// Normaliza la dificultad guardada ("moderada", "alta"...) a
/// uno de [kNivelesDificultad].
String nivelDificultad(String dificultad) {
  final d = dificultad.toLowerCase();
  if (d.contains('dificil') || d.contains('alta') || d.contains('exigente')) {
    return 'dificil';
  }
  if (d.contains('moderada') || d.contains('media')) return 'media';
  return 'facil';
}

/// Mismo código de colores que la app: verde, ámbar y rojo.
Color colorDificultad(String dificultad) {
  switch (nivelDificultad(dificultad)) {
    case 'dificil':
      return const Color(0xFFDC2626);
    case 'media':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF16A34A);
  }
}

/// Ilustración de respaldo (mismos dibujos que la app móvil).
CustomPainter painterParaActividad(String nombre) {
  final name = nombre.toLowerCase();
  if (name.contains('trekking') || name.contains('senderismo') || name.contains('cañón')) {
    return TrailHikerPainter();
  }
  if (name.contains('caballo') || name.contains('cabalgata')) {
    return HorseValleyPainter();
  }
  if (name.contains('ave') || name.contains('amboró') || name.contains('eco')) {
    return ForestCanopyPainter();
  }
  if (name.contains('bici') || name.contains('aventura') || name.contains('cactus')) {
    return BikeAdventurePainter();
  }
  return CulturalTraditionPainter();
}
