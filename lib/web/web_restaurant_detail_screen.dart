import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/gastronomia_item.dart';
import '../models/restaurante.dart';
import '../repositories/gastronomia_repository.dart';
import '../widgets/resenas_section.dart';
import 'web_components.dart';
import 'web_gastronomy_detail_screen.dart';
import 'web_theme.dart';
import 'web_widgets.dart';

/// Detalle de un restaurante para la versión web de escritorio.
class WebRestaurantDetailScreen extends StatefulWidget {
  const WebRestaurantDetailScreen({super.key, required this.restaurante});

  final Restaurante restaurante;

  @override
  State<WebRestaurantDetailScreen> createState() =>
      _WebRestaurantDetailScreenState();
}

class _WebRestaurantDetailScreenState extends State<WebRestaurantDetailScreen> {
  double _promedioResenas = 0;
  int _totalResenas = 0;

  List<GastronomiaItem> _platos = <GastronomiaItem>[];
  bool _cargandoPlatos = false;

  Restaurante get _r => widget.restaurante;

  LatLng? get _punto {
    final lat = _r.latitud;
    final lng = _r.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final id = _r.id;
    if (id != null) _cargarPlatos(id);
  }

  Future<void> _cargarPlatos(String restauranteId) async {
    setState(() => _cargandoPlatos = true);
    try {
      final platos = await context
          .read<GastronomiaRepository>()
          .fetchByRestaurante(restauranteId);
      if (!mounted) return;
      setState(() {
        _platos = platos;
        _cargandoPlatos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoPlatos = false);
    }
  }

  void _contactar() {
    final contacto = textoONulo(_r.contacto);
    if (contacto == null) return;
    final horario = textoONulo(_r.horarioAtencion);
    showWebContactDialog(
      context,
      nombre: _r.nombre,
      contacto: contacto,
      rol: 'Teléfono de contacto',
      icono: Icons.phone,
      extras: [
        if (horario != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFFC68B59)),
              const SizedBox(width: 10),
              Expanded(child: Text('Horario habitual: $horario')),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final horario = textoONulo(_r.horarioAtencion);
    final direccion = textoONulo(_r.direccionReferencia);

    return WebDetailScaffold(
      seccion: 'Restaurantes',
      titulo: _r.nombre,
      encabezado: WebDetailHeader(
        categoria: textoONulo(_r.categoriaNombre) ?? 'Restaurante',
        nombre: _r.nombre,
        promedio: _promedioResenas,
        total: _totalResenas,
        extras: [
          if (horario != null)
            WebIconText(icono: Icons.access_time, texto: horario),
          if (direccion != null)
            WebIconText(icono: Icons.place_outlined, texto: direccion),
        ],
      ),
      galeria: (ancho) => WebGaleria(
        imagenes: _r.imagenes,
        respaldo: const WebIconoRespaldo(icono: Icons.storefront, calido: true),
        ancho: ancho,
      ),
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebDescripcion(
            titulo: 'Sobre el restaurante',
            texto: _r.descripcion,
            vacio: 'Este restaurante todavía no tiene descripción.',
          ),
          _buildPlatos(),
          if (_r.id != null)
            ResenasSection(
              entidad: 'restaurante',
              entidadId: _r.id!,
              onResumenActualizado: (promedio, total) {
                setState(() {
                  _promedioResenas = promedio;
                  _totalResenas = total;
                });
              },
            ),
        ],
      ),
      lateral: _buildLateral(horario, direccion),
    );
  }

  Widget _buildPlatos() {
    if (!_cargandoPlatos && _platos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebSectionTitle('Platos típicos que ofrece'),
          const SizedBox(height: 16),
          if (_cargandoPlatos)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final plato in _platos)
                  SizedBox(width: 340, child: _buildPlato(plato)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlato(GastronomiaItem plato) {
    final precio = precioBs(plato.precioReferencial);
    return WebHoverCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WebGastronomyDetailScreen(item: plato),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF9EFE5),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: plato.imagenes.isNotEmpty
                  ? Image.network(
                      plato.imagenes.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFFC68B59),
                      ),
                    )
                  : const Icon(Icons.restaurant_menu, color: Color(0xFFC68B59)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plato.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (plato.descripcion.trim().isNotEmpty)
                    Text(
                      plato.descripcion.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            if (precio.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                precio,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WebTheme.verde,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLateral(String? horario, String? direccion) {
    final precio = _r.precioReferencial;
    final precioTexto =
        precio != null && precio > 0 ? 'Bs ${precio.toInt()}' : '';
    final contacto = textoONulo(_r.contacto);
    final punto = _punto;

    return Column(
      children: [
        WebReservaCard(
          etiquetaPrecio: 'Precio referencial',
          precio: precioTexto,
          sufijoPrecio: 'por persona',
          rolContacto: 'Contacto',
          nombreContacto: contacto,
          iconoContacto: Icons.phone_in_talk_outlined,
          textoBoton: 'Contactar / Reservar',
          onContactar: contacto != null ? _contactar : null,
        ),
        WebTarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WebCardTitle('Información'),
              const SizedBox(height: 16),
              WebDato(
                icono: Icons.restaurant_outlined,
                titulo: 'Tipo',
                valor: textoONulo(_r.categoriaNombre) ?? 'Restaurante',
              ),
              if (horario != null)
                WebDato(
                  icono: Icons.access_time_outlined,
                  titulo: 'Horario',
                  valor: horario,
                ),
              if (precioTexto.isNotEmpty)
                WebDato(
                  icono: Icons.payments_outlined,
                  titulo: 'Precios',
                  valor: '$precioTexto ref.',
                ),
              if (contacto != null)
                WebDato(
                  icono: Icons.phone_in_talk_outlined,
                  titulo: 'Contacto',
                  valor: contacto,
                ),
              if (_r.calificacionPromedio > 0)
                WebDato(
                  icono: Icons.star_outline,
                  titulo: 'Calificación',
                  valor: _r.calificacionPromedio.toStringAsFixed(1),
                ),
            ],
          ),
        ),
        if (punto != null) ...[
          const SizedBox(height: 20),
          WebUbicacionCard(
            titulo: 'Ubicación y mapa',
            nombreDestino: _r.nombre,
            punto: punto,
            detalle: direccion,
          ),
        ],
      ],
    );
  }
}
