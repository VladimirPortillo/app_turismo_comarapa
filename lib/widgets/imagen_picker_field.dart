import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/image_upload_service.dart';

const Color _kPrimary = Color(0xFF1B5A3F);
const Color _kAccent = Color(0xFF2A7353);

/// Campo reutilizable para elegir/subir fotos (cámara o galería) de una
/// entidad de turismo. Sube el archivo a Supabase Storage y expone la
/// lista resultante de URLs vía [onChanged]. La primera URL de la lista es
/// la que usan todas las pantallas públicas como imagen de portada.
class ImagenPickerField extends StatefulWidget {
  const ImagenPickerField({
    super.key,
    required this.imagenes,
    required this.onChanged,
    required this.carpeta,
  });

  final List<String> imagenes;
  final ValueChanged<List<String>> onChanged;
  final String carpeta;

  @override
  State<ImagenPickerField> createState() => _ImagenPickerFieldState();
}

class _ImagenPickerFieldState extends State<ImagenPickerField> {
  bool _subiendo = false;

  bool get _puedeUsarCamara =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _elegirOrigen() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Agregar imagen',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0C3D28),
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ),
              if (_puedeUsarCamara)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: _kPrimary),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _kPrimary),
                title: const Text('Elegir de galería'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _subiendo = true);
    try {
      final service = context.read<ImageUploadService>();
      final url = await service.pickAndUpload(carpeta: widget.carpeta, source: source);
      if (url != null) {
        widget.onChanged([...widget.imagenes, url]);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la imagen: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _quitar(int index) {
    final actualizadas = [...widget.imagenes]..removeAt(index);
    widget.onChanged(actualizadas);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imágenes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < widget.imagenes.length; i++) ...[
                _buildThumbnail(widget.imagenes[i], esPrincipal: i == 0, onRemove: () => _quitar(i)),
                const SizedBox(width: 10),
              ],
              _buildAddTile(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(String url, {required bool esPrincipal, required VoidCallback onRemove}) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 88,
                height: 88,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_outlined, color: Colors.white),
              ),
            ),
          ),
          if (esPrincipal)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE26A2C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRINCIPAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _subiendo ? null : _elegirOrigen,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: _subiendo
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
              )
            : const Icon(Icons.add_a_photo_outlined, color: _kAccent, size: 26),
      ),
    );
  }
}
