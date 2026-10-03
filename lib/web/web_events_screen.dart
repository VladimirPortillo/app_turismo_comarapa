import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../repositories/evento_repository.dart';
import '../screens/events_screen.dart'
    show
        CulturalDancePainter,
        EventGenericPainter,
        FairCarnivalPainter,
        FestivalMusicPainter,
        PatronalFeastPainter;
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_event_detail_screen.dart';

/// Calendario de eventos para la versión web de escritorio.
class WebEventsScreen extends StatelessWidget {
  const WebEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<Evento>(
      antetitulo: 'Celebra con',
      lema: 'Ferias, fiestas patronales, festivales y cultura',
      hint: 'Buscar ferias, fiestas, festivales...',
      singular: 'evento encontrado',
      plural: 'eventos encontrados',
      iconoVacio: Icons.event_busy_outlined,
      cargar: (context) => context.read<EventoRepository>().fetchActivos(),
      orden: (a, b) => a.fechaInicio.compareTo(b.fechaInicio),
      categoria: (e) => e.categoriaNombre,
      iconoCategoria: iconoCategoriaEvento,
      imagenes: (e) => e.imagenes,
      textoBusqueda: (e) =>
          '${e.nombre} ${e.descripcion} ${e.periodicidad ?? ''}',
      filtros: [
        CatFiltro<Evento>(
          titulo: 'Cuándo',
          icono: Icons.schedule,
          opciones: (_) => [
            CatOpcion('Próximos', (e) => !eventoFinalizado(e)),
            CatOpcion('Finalizados', eventoFinalizado),
          ],
        ),
        CatFiltro<Evento>(
          titulo: 'Mes',
          icono: Icons.calendar_month_outlined,
          opciones: (items) {
            final meses = items.map((e) => e.fechaInicio.month).toSet().toList()
              ..sort();
            return [
              for (final m in meses)
                CatOpcion(kMesesCortos[m - 1], (e) => e.fechaInicio.month == m),
            ];
          },
        ),
      ],
      tarjeta: (e) {
        final periodicidad = periodicidadTexto(e);
        final finalizado = eventoFinalizado(e);
        return CatTarjeta(
          titulo: e.nombre,
          imagenes: e.imagenes,
          respaldo: painterParaEvento(e.categoriaNombre ?? '', e.nombre),
          categoria: textoONulo(e.categoriaNombre),
          iconoTitulo: Icons.celebration,
          etiqueta: finalizado ? 'Finalizado' : fechaCorta(e),
          atenuada: finalizado,
          datos: [
            CatDato(Icons.event_outlined, fechaCorta(e)),
            if (periodicidad != null) CatDato(Icons.repeat, periodicidad),
          ],
          descripcion: e.descripcion,
          abrirDetalle: (_) => WebEventDetailScreen(evento: e),
        );
      },
    );
  }
}

// ================================================================ Helpers

const List<String> kMesesCortos = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

const List<String> kMesesLargos = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// True si el evento ya terminó (se compara solo la fecha, sin hora).
bool eventoFinalizado(Evento e) {
  final hoy = _soloFecha(DateTime.now());
  return _soloFecha(e.fechaFin ?? e.fechaInicio).isBefore(hoy);
}

/// "21 Mar", "21 - 23 Mar" o "30 Mar - 2 Abr" (mismo formato que la app).
String fechaCorta(Evento e) {
  final inicio = e.fechaInicio;
  final fin = e.fechaFin;
  final mes = kMesesCortos[inicio.month - 1];
  if (fin != null && (fin.day != inicio.day || fin.month != inicio.month)) {
    if (fin.month == inicio.month) return '${inicio.day} - ${fin.day} $mes';
    return '${inicio.day} $mes - ${fin.day} ${kMesesCortos[fin.month - 1]}';
  }
  return '${inicio.day} $mes';
}

/// "Periodicidad" con la primera letra en mayúscula, o null.
String? periodicidadTexto(Evento e) {
  final per = textoONulo(e.periodicidad);
  if (per == null) return null;
  return per[0].toUpperCase() + per.substring(1).toLowerCase();
}

/// Ícono según el tipo de evento.
IconData iconoCategoriaEvento(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('feria')) return Icons.storefront_outlined;
  if (c.contains('patronal') || c.contains('relig')) return Icons.church_outlined;
  if (c.contains('festival') || c.contains('música') || c.contains('musica')) {
    return Icons.music_note_outlined;
  }
  if (c.contains('cultur') || c.contains('cívico') || c.contains('civico')) {
    return Icons.theater_comedy_outlined;
  }
  if (c.contains('deport')) return Icons.sports_soccer_outlined;
  return Icons.celebration_outlined;
}

/// Ilustración de respaldo (mismos dibujos que la app móvil).
CustomPainter painterParaEvento(String categoria, String nombre) {
  final cat = categoria.toLowerCase();
  final name = nombre.toLowerCase();
  if (cat.contains('feria') || name.contains('durazno')) {
    return FairCarnivalPainter();
  }
  if (cat.contains('patronal') || name.contains('candelaria') || name.contains('virgen')) {
    return PatronalFeastPainter();
  }
  if (cat.contains('festival') || name.contains('música') || name.contains('musica')) {
    return FestivalMusicPainter();
  }
  if (cat.contains('cultural') || cat.contains('cívico') || cat.contains('civico')) {
    return CulturalDancePainter();
  }
  return EventGenericPainter();
}

/// Cuadro con día y mes, como una hoja de calendario (detalle del evento).
class WebFechaBadge extends StatelessWidget {
  const WebFechaBadge({super.key, required this.evento, this.grande = false});

  final Evento evento;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: grande ? 84 : 56,
      padding: EdgeInsets.symmetric(vertical: grande ? 12 : 6),
      decoration: BoxDecoration(
        color: grande ? evento.badgeBgColor : Colors.white,
        borderRadius: BorderRadius.circular(grande ? 18 : 12),
        boxShadow: grande
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            evento.diaFormateado,
            style: TextStyle(
              fontSize: grande ? 32 : 20,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: evento.badgeTextColor,
            ),
          ),
          Text(
            evento.mesAbreviado,
            style: TextStyle(
              fontSize: grande ? 13 : 11,
              fontWeight: FontWeight.bold,
              color: evento.badgeTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
