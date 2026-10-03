import 'package:flutter/material.dart';

/// Paleta y medidas usadas solo por el diseño web.
class WebTheme {
  WebTheme._();

  static const Color verdeOscuro = Color(0xFF0C3D28);
  static const Color verde = Color(0xFF1B5A3F);
  static const Color verdeClaro = Color(0xFFE8F3EF);
  static const Color durazno = Color(0xFFC68B59);
  static const Color fondo = Color(0xFFFAF9F6);
  static const Color texto = Color(0xFF374151);

  /// Ancho máximo del contenido en pantallas grandes.
  static const double maxWidth = 1200;

  /// Por debajo de este ancho se usa el diseño móvil original.
  static const double breakpoint = 900;
}

/// Tarjeta blanca que se eleva al pasar el mouse.
class WebHoverCard extends StatefulWidget {
  const WebHoverCard({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<WebHoverCard> createState() => _WebHoverCardState();
}

class _WebHoverCardState extends State<WebHoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.10 : 0.03),
                blurRadius: _hover ? 24 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Centra el contenido y lo limita a [WebTheme.maxWidth].
class WebContainer extends StatelessWidget {
  const WebContainer({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: WebTheme.maxWidth),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 32),
          child: child,
        ),
      ),
    );
  }
}
