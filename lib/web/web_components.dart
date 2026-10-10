import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'web_theme.dart';
import 'web_widgets.dart';

// Componentes genéricos que comparten todas las secciones web
// (lugares, actividades, gastronomía, hoteles, restaurantes, eventos).

/// Etiqueta pequeña de color (categoría, temporada...).
class WebBadge extends StatelessWidget {
  const WebBadge({
    super.key,
    required this.texto,
    this.fondo = WebTheme.verdeClaro,
    this.color = WebTheme.verde,
    this.icono,
  });

  /// Variante en tonos durazno, usada en gastronomía y restaurantes.
  const WebBadge.calido({super.key, required this.texto, this.icono})
    : fondo = const Color(0xFFF9EFE5),
      color = const Color(0xFFB45309);

  /// Variante ámbar, usada para temporada / periodicidad.
  const WebBadge.ambar({super.key, required this.texto, this.icono})
    : fondo = const Color(0xFFFEF3C7),
      color = const Color(0xFFB45309);

  final String texto;
  final Color fondo;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono + texto gris para la fila de metadatos de una tarjeta.
class WebMeta extends StatelessWidget {
  const WebMeta({
    super.key,
    required this.icono,
    required this.texto,
    this.color,
  });

  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color ?? Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: c),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta genérica de la cuadrícula: imagen (o dibujo de respaldo),
/// etiqueta flotante sobre la imagen, badges, título, descripción y metadatos.
class WebEntityCard extends StatelessWidget {
  const WebEntityCard({
    super.key,
    required this.imagenes,
    required this.respaldo,
    required this.titulo,
    required this.onTap,
    this.badges = const <Widget>[],
    this.descripcion,
    this.meta = const <Widget>[],
    this.etiquetaImagen,
    this.esquinaImagen,
  });

  final List<String> imagenes;
  final CustomPainter respaldo;
  final String titulo;
  final VoidCallback onTap;
  final List<Widget> badges;
  final String? descripcion;
  final List<Widget> meta;

  /// Texto destacado arriba a la derecha de la imagen (precio, calificación...).
  final Widget? etiquetaImagen;

  /// Widget arriba a la izquierda de la imagen (ej. fecha de un evento).
  final Widget? esquinaImagen;

  @override
  Widget build(BuildContext context) {
    final dibujo = CustomPaint(painter: respaldo);
    final desc = descripcion?.trim() ?? '';

    return WebHoverCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                imagenes.isNotEmpty
                    ? Image.network(
                        imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => dibujo,
                      )
                    : dibujo,
                if (etiquetaImagen != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: WebTheme.verdeOscuro,
                        ),
                        child: etiquetaImagen!,
                      ),
                    ),
                  ),
                if (esquinaImagen != null)
                  Positioned(top: 12, left: 12, child: esquinaImagen!),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badges.isNotEmpty) ...[
                  Row(
                    children: [
                      for (var i = 0; i < badges.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Flexible(child: badges[i]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.verdeOscuro,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < meta.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Flexible(child: meta[i]),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrella + calificación, para la etiqueta sobre la imagen.
class WebRating extends StatelessWidget {
  const WebRating(this.valor, {super.key});

  final num valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Color(0xFFD97706)),
        const SizedBox(width: 4),
        Text(valor.toStringAsFixed(1)),
      ],
    );
  }
}

/// Diálogo centrado con un dato de contacto y botón para copiarlo.
void showWebContactDialog(
  BuildContext context, {
  required String nombre,
  required String contacto,
  required String rol,
  required IconData icono,
  List<Widget> extras = const <Widget>[],
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Contacto y reservas',
        style: TextStyle(
          color: WebTheme.verdeOscuro,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de contacto registrada para "$nombre":',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7E2D6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF26674B),
                    child: Icon(icono, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rol.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          contacto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: WebTheme.verdeOscuro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...extras,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF26674B),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            Clipboard.setData(ClipboardData(text: contacto));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contacto "$contacto" copiado al portapapeles'),
                behavior: SnackBarBehavior.floating,
                width: 420,
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar contacto'),
        ),
      ],
    ),
  );
}

/// Tarjeta lateral de reserva: precio destacado + contacto + botón.
/// Si no hay precio ni contacto no muestra nada.
class WebReservaCard extends StatelessWidget {
  const WebReservaCard({
    super.key,
    required this.etiquetaPrecio,
    required this.precio,
    this.sufijoPrecio,
    required this.rolContacto,
    required this.nombreContacto,
    required this.iconoContacto,
    required this.textoBoton,
    required this.onContactar,
  });

  final String etiquetaPrecio;
  final String precio;
  final String? sufijoPrecio;
  final String rolContacto;

  /// Texto mostrado bajo el rol (ej. nombre del operador). Null si no hay.
  final String? nombreContacto;
  final IconData iconoContacto;
  final String textoBoton;

  /// Null si no hay contacto registrado.
  final VoidCallback? onContactar;

  @override
  Widget build(BuildContext context) {
    if (precio.isEmpty && onContactar == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: WebTarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (precio.isNotEmpty) ...[
              Text(
                etiquetaPrecio.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  Text(
                    precio,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.verdeOscuro,
                    ),
                  ),
                  if (sufijoPrecio != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        sufijoPrecio!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ],
            if (onContactar != null) ...[
              if (precio.isNotEmpty) const SizedBox(height: 16),
              if (nombreContacto != null) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: WebTheme.verdeClaro,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconoContacto, color: WebTheme.verde),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rolContacto,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            nombreContacto!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: onContactar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF26674B),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.contact_phone_outlined),
                label: Text(
                  textoBoton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fondo degradado verde con un ícono grande, para detalles sin foto.
class WebIconoRespaldo extends StatelessWidget {
  const WebIconoRespaldo({super.key, required this.icono, this.calido = false});

  final IconData icono;
  final bool calido;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: calido
              ? const [Color(0xFF7C4A1E), Color(0xFFA8672F), Color(0xFFC68B59)]
              : const [Color(0xFF0F3924), Color(0xFF1B5A3F), Color(0xFF2E7D58)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 72, color: Colors.white),
        ),
      ),
    );
  }
}

/// Descripción larga de la columna principal (con texto por defecto).
class WebDescripcion extends StatelessWidget {
  const WebDescripcion({
    super.key,
    required this.titulo,
    required this.texto,
    required this.vacio,
  });

  final String titulo;
  final String texto;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    final t = texto.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebSectionTitle(titulo),
        const SizedBox(height: 12),
        Text(
          t.isNotEmpty ? t : vacio,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF4B5563),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

/// "Bs 25", "Gratis" o vacío si no hay precio registrado.
String precioBs(num? precio) {
  if (precio == null) return '';
  if (precio <= 0) return 'Gratis';
  return 'Bs ${precio.toInt()}';
}

/// Texto no vacío o null.
String? textoONulo(String? valor) {
  final t = valor?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

// ------------------------------------------------------- Panel responsive

/// Ancho a partir del cual el panel admin muestra la barra lateral fija.
/// Por debajo, la barra lateral pasa a un menú desplegable (drawer).
const double kAnchoPanelEscritorio = 900;

/// Ancho a partir del cual las tablas del panel se muestran como tabla;
/// por debajo, cada fila se muestra como una tarjeta apilada.
const double kAnchoTablaCompleta = 760;

/// Ancho para los SnackBar flotantes: fijo en pantallas anchas y
/// automático (todo el ancho con márgenes) en pantallas angostas.
double? anchoSnackBar(BuildContext context, [double ancho = 460]) {
  return MediaQuery.sizeOf(context).width < ancho + 48 ? null : ancho;
}

/// Coloca las tarjetas de estadísticas en 4, 2 o 1 columnas
/// según el ancho disponible.
class WebStatsGrid extends StatelessWidget {
  const WebStatsGrid({super.key, required this.children, this.espacio = 16});

  final List<Widget> children;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho >= 820
            ? children.length
            : ancho >= 380
            ? 2
            : 1;
        final anchoItem = (ancho - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final c in children) SizedBox(width: anchoItem, child: c),
          ],
        );
      },
    );
  }
}
