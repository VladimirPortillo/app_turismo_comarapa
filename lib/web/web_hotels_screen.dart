import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotel.dart';
import '../repositories/hotel_repository.dart';
import '../screens/hotels_screen.dart'
    show
        CabinWoodPainter,
        CampingTentPainter,
        HostelCozyPainter,
        HotelFacadePainter;
import 'web_catalogo.dart';
import 'web_components.dart';
import 'web_hotel_detail_screen.dart';

/// Listado de hospedajes para la versión web de escritorio.
class WebHotelsScreen extends StatelessWidget {
  const WebHotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebCatalogo<Hotel>(
      antetitulo: 'Descansa en',
      lema: 'Hoteles, hostales, cabañas y camping para tu estadía',
      hint: 'Buscar hoteles, hostales, cabañas...',
      singular: 'hospedaje encontrado',
      plural: 'hospedajes encontrados',
      iconoVacio: Icons.hotel_outlined,
      cargar: (context) => context.read<HotelRepository>().fetchActivos(),
      categoria: (h) => h.categoriaNombre,
      iconoCategoria: iconoCategoriaHotel,
      imagenes: (h) => h.imagenes,
      textoBusqueda: (h) =>
          '${h.nombre} ${h.descripcion} ${h.direccionReferencia ?? ''}',
      filtros: [
        CatFiltro<Hotel>(
          titulo: 'Servicios',
          icono: Icons.room_service_outlined,
          multiple: true,
          opciones: (items) {
            // Los servicios más frecuentes entre los hospedajes cargados.
            final conteo = <String, int>{};
            for (final h in items) {
              for (final s in h.servicios) {
                final nombre = s.trim();
                if (nombre.isNotEmpty) conteo[nombre] = (conteo[nombre] ?? 0) + 1;
              }
            }
            final servicios = conteo.keys.toList()
              ..sort((a, b) => conteo[b]!.compareTo(conteo[a]!));
            return [
              for (final s in servicios.take(8))
                CatOpcion(s, (h) => h.servicios.any((x) => x.trim() == s)),
            ];
          },
        ),
        CatFiltro<Hotel>(
          titulo: 'Calificación',
          icono: Icons.star_outline,
          opciones: (_) => [
            CatOpcion('4+ ★', (h) => h.calificacionPromedio >= 4),
            CatOpcion('3+ ★', (h) => h.calificacionPromedio >= 3),
          ],
        ),
      ],
      tarjeta: (h) {
        final precio = preciosHotel(h);
        final direccion = textoONulo(h.direccionReferencia);
        return CatTarjeta(
          titulo: h.nombre,
          imagenes: h.imagenes,
          respaldo: painterParaHotel(h.categoriaNombre ?? '', h.nombre),
          categoria: textoONulo(h.categoriaNombre),
          iconoTitulo: Icons.hotel,
          etiqueta: h.calificacionPromedio > 0
              ? '★ ${h.calificacionPromedio.toStringAsFixed(1)}'
              : null,
          datos: [
            if (precio.isNotEmpty)
              CatDato(Icons.payments_outlined, '$precio / noche'),
            if (direccion != null) CatDato(Icons.place_outlined, direccion),
            for (final s in h.servicios.take(3)) CatDato(iconoServicio(s), s),
          ],
          descripcion: h.descripcion,
          abrirDetalle: (_) => WebHotelDetailScreen(hotel: h),
        );
      },
    );
  }
}

/// "Bs 150 - 300", "Desde Bs 150"... o vacío si no hay precios.
String preciosHotel(Hotel h) {
  final min = h.precioMin;
  final max = h.precioMax;
  if (min != null && max != null) return 'Bs ${min.toInt()} - ${max.toInt()}';
  if (min != null) return 'Desde Bs ${min.toInt()}';
  if (max != null) return 'Hasta Bs ${max.toInt()}';
  return '';
}

/// Ícono según el nombre del servicio (mismo criterio que la app).
IconData iconoServicio(String servicio) {
  final a = servicio.toLowerCase();
  if (a.contains('wifi')) return Icons.wifi;
  if (a.contains('parqueo') || a.contains('estacionamiento')) {
    return Icons.local_parking;
  }
  if (a.contains('desayuno') || a.contains('café')) return Icons.coffee_outlined;
  if (a.contains('agua') || a.contains('baño')) return Icons.hot_tub_outlined;
  if (a.contains('fogata')) return Icons.local_fire_department_outlined;
  if (a.contains('piscina')) return Icons.pool;
  if (a.contains('aire') || a.contains('clima')) return Icons.ac_unit;
  return Icons.check_circle_outline;
}

/// Ícono según el tipo de hospedaje.
IconData iconoCategoriaHotel(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('cabaña') || c.contains('cabana')) return Icons.cabin_outlined;
  if (c.contains('camping')) return Icons.forest_outlined;
  if (c.contains('hostal') || c.contains('residencial')) {
    return Icons.night_shelter_outlined;
  }
  return Icons.hotel_outlined;
}

/// Ilustración de respaldo (mismos dibujos que la app móvil).
CustomPainter painterParaHotel(String categoria, String nombre) {
  final cat = categoria.toLowerCase();
  final name = nombre.toLowerCase();
  if (cat.contains('cabaña') || name.contains('cabaña')) return CabinWoodPainter();
  if (cat.contains('camping') || name.contains('camping')) {
    return CampingTentPainter();
  }
  if (cat.contains('hostal') || name.contains('residencial')) {
    return HostelCozyPainter();
  }
  return HotelFacadePainter();
}
