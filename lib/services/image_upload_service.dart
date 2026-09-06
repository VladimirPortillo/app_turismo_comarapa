import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sube imágenes al bucket público `comarapa-imagenes` de Supabase Storage
/// y retorna la URL pública para guardarla en la columna `imagenes` de
/// cada tabla (lugares, hoteles, actividades, gastronomia, etc.).
class ImageUploadService {
  ImageUploadService(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'comarapa-imagenes';

  final ImagePicker _picker = ImagePicker();

  /// Abre el selector de [source] (cámara o galería), sube la foto elegida
  /// dentro de la carpeta [carpeta] del bucket y retorna la URL pública.
  /// Retorna null si el usuario cancela la selección.
  Future<String?> pickAndUpload({
    required String carpeta,
    required ImageSource source,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final path = '$carpeta/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
