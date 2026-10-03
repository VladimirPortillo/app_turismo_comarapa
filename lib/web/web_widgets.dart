import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../screens/home_screen.dart' show GreenMountainLogoPainter;
import '../widgets/full_map_sheet.dart';
import '../widgets/fullscreen_image_gallery.dart';
import 'web_theme.dart';

// Piezas reutilizables por las pantallas web de listado y detalle.

/// Texto de duración ("45 min", "2 horas"...). Devuelve [vacio] si no hay dato.
String duracionLabel(int? minutos, {String vacio = 'Duración libre'}) {
  if (minutos == null || minutos <= 0) return vacio;
  if (minutos < 60) return '$minutos min';
  final horas = minutos / 60;
  final texto = horas == horas.roundToDouble()
      ? horas.toInt().toString()
      : horas.toStringAsFixed(1);
  return '$texto ${horas == 1 ? "hora" : "horas"}';
}

/// Muestra el mapa con ruta ([FullMapSheet]) en un diálogo centrado.
void showWebMapDialog(
  BuildContext context, {
  required String titulo,
  String? subtitulo,
  required LatLng destino,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 1000,
        height: 720,
        child: FullMapSheet(
          titulo: titulo,
          subtitulo: subtitulo,
          destino: destino,
        ),
      ),
    ),
  );
}

/// Mensaje centrado para estados vacíos o de error.
class WebMensaje extends StatelessWidget {
  const WebMensaje({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.texto,
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 8),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    );
  }
}

// ================================================================ Detalles

/// Estructura común de una pantalla de detalle web: barra superior con
/// ruta de navegación, encabezado, galería y contenido en dos columnas
/// (se apilan si la ventana es angosta).
class WebDetailScaffold extends StatelessWidget {
  const WebDetailScaffold({
    super.key,
    required this.seccion,
    required this.titulo,
    required this.encabezado,
    required this.galeria,
    required this.principal,
    required this.lateral,
  });

  final String seccion;
  final String titulo;
  final Widget encabezado;
  final Widget Function(bool ancho) galeria;
  final Widget principal;
  final Widget lateral;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebTheme.fondo,
      body: Column(
        children: [
          _buildTopBar(context),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: WebContainer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ancho = constraints.maxWidth >= 860;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        encabezado,
                        const SizedBox(height: 24),
                        galeria(ancho),
                        const SizedBox(height: 36),
                        if (ancho)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: principal),
                              const SizedBox(width: 40),
                              SizedBox(width: 360, child: lateral),
                            ],
                          )
                        else ...[
                          lateral,
                          const SizedBox(height: 36),
                          principal,
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 72,
      child: WebContainer(
        child: Row(
          children: [
            CustomPaint(
              size: const Size(28, 24),
              painter: GreenMountainLogoPainter(),
            ),
            const SizedBox(width: 10),
            const Text(
              'Comarapa',
              style: TextStyle(
                color: WebTheme.verdeOscuro,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(width: 32),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver'),
              style: TextButton.styleFrom(foregroundColor: WebTheme.texto),
            ),
            Text('  /  ', style: TextStyle(color: Colors.grey.shade400)),
            Text(seccion, style: TextStyle(color: Colors.grey.shade600)),
            Text('  /  ', style: TextStyle(color: Colors.grey.shade400)),
            Flexible(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WebTheme.verdeOscuro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado del detalle: categoría, nombre, estrellas y datos extra.
class WebDetailHeader extends StatelessWidget {
  const WebDetailHeader({
    super.key,
    required this.categoria,
    required this.nombre,
    required this.promedio,
    required this.total,
    this.extras = const <Widget>[],
  });

  final String categoria;
  final String nombre;
  final double promedio;
  final int total;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: WebTheme.verdeClaro,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            categoria.toUpperCase(),
            style: const TextStyle(
              color: WebTheme.verde,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nombre,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: WebTheme.verdeOscuro,
            fontFamily: 'serif',
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Icon(
                    i < promedio.round() ? Icons.star : Icons.star_border,
                    size: 20,
                    color: const Color(0xFFE59819),
                  ),
                const SizedBox(width: 8),
                Text(
                  total == 0
                      ? 'Sin reseñas todavía'
                      : '${promedio.toStringAsFixed(1)} · $total '
                          '${total == 1 ? "reseña" : "reseñas"}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
            ...extras,
          ],
        ),
      ],
    );
  }
}

/// Ícono + texto gris pequeño, para usar como extra del encabezado.
class WebIconText extends StatelessWidget {
  const WebIconText({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: WebTheme.verde),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    );
  }
}

/// Galería tipo mosaico: foto grande + hasta 2 miniaturas ("+N fotos").
/// Al hacer clic abre la galería a pantalla completa.
class WebGaleria extends StatelessWidget {
  const WebGaleria({
    super.key,
    required this.imagenes,
    required this.respaldo,
    required this.ancho,
  });

  final List<String> imagenes;
  final Widget respaldo;
  final bool ancho;

  static const double _alto = 440;

  @override
  Widget build(BuildContext context) {
    if (imagenes.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(height: _alto, width: double.infinity, child: respaldo),
      );
    }

    if (imagenes.length == 1 || !ancho) {
      return SizedBox(
        height: _alto,
        width: double.infinity,
        child: _foto(context, 0, BorderRadius.circular(24)),
      );
    }

    final extras = imagenes.length - 3;
    return SizedBox(
      height: _alto,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _foto(
              context,
              0,
              const BorderRadius.horizontal(left: Radius.circular(24)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _foto(
                    context,
                    1,
                    BorderRadius.only(
                      topRight: const Radius.circular(24),
                      bottomRight: imagenes.length == 2
                          ? const Radius.circular(24)
                          : Radius.zero,
                    ),
                  ),
                ),
                if (imagenes.length > 2) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _foto(
                          context,
                          2,
                          const BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        if (extras > 0)
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+$extras fotos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foto(BuildContext context, int index, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        child: GestureDetector(
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
          child: SizedBox.expand(
            child: Image.network(
              imagenes[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => respaldo,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con borde, para la columna lateral.
class WebTarjeta extends StatelessWidget {
  const WebTarjeta({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Fila "ícono · título ........ valor" para las tarjetas de información.
class WebDato extends StatelessWidget {
  const WebDato({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.colorValor,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WebTheme.verdeClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 20, color: WebTheme.verde),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(titulo, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorValor ?? const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de tarjeta lateral.
class WebCardTitle extends StatelessWidget {
  const WebCardTitle(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: WebTheme.verdeOscuro,
      ),
    );
  }
}

/// Título de sección de la columna principal.
class WebSectionTitle extends StatelessWidget {
  const WebSectionTitle(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: WebTheme.verdeOscuro,
        fontFamily: 'serif',
      ),
    );
  }
}

/// Tarjeta con mini mapa arrastrable, texto y botón "Cómo llegar".
class WebUbicacionCard extends StatelessWidget {
  const WebUbicacionCard({
    super.key,
    required this.titulo,
    required this.nombreDestino,
    required this.punto,
    this.detalle,
  });

  final String titulo;
  final String nombreDestino;
  final LatLng punto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return WebTarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 14,
                // Sin zoom con la rueda para no interferir con el scroll.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Color(0xFF26674B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WebCardTitle(titulo),
                if (detalle?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    detalle!,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => showWebMapDialog(
                    context,
                    titulo: nombreDestino,
                    subtitulo: detalle,
                    destino: punto,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF26674B),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text(
                    'Cómo llegar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
