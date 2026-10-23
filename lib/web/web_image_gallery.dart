import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visor de imágenes a pantalla completa para la web: flechas a los lados
/// (y teclas ← / →) para recorrer las imágenes, zoom y botón para cerrar.
class WebImageGallery extends StatefulWidget {
  const WebImageGallery({
    super.key,
    required this.imagenes,
    this.initialIndex = 0,
  });

  final List<String> imagenes;
  final int initialIndex;

  @override
  State<WebImageGallery> createState() => _WebImageGalleryState();
}

class _WebImageGalleryState extends State<WebImageGallery> {
  late final PageController _controller;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _irA(int index) {
    if (index < 0 || index >= widget.imagenes.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _irA(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _irA(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _flecha({
    required IconData icono,
    required bool habilitada,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: habilitada ? 1 : 0.25,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          iconSize: 34,
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          icon: Icon(icono),
          onPressed: habilitada ? onTap : null,
          disabledColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagenes.length;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imagenes[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (total > 1) ...[
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _flecha(
                    icono: Icons.chevron_left,
                    habilitada: _currentIndex > 0,
                    onTap: () => _irA(_currentIndex - 1),
                    tooltip: 'Anterior',
                  ),
                ),
              ),
              Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _flecha(
                    icono: Icons.chevron_right,
                    habilitada: _currentIndex < total - 1,
                    onTap: () => _irA(_currentIndex + 1),
                    tooltip: 'Siguiente',
                  ),
                ),
              ),
            ],
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Cerrar',
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (total > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (total > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (index) {
                    final isActive = index == _currentIndex;
                    return GestureDetector(
                      onTap: () => _irA(index),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: 6),
                          width: isActive ? 22 : 8,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
