import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/restaurante.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/restaurante_repository.dart';
import '../widgets/imagen_picker_field.dart';
import '../widgets/fullscreen_location_picker.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Restaurante? restaurante;

  const EditRestaurantScreen({
    super.key,
    this.restaurante,
  });

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _horarioController;
  late final TextEditingController _precioRefController;
  late final TextEditingController _contactoController;
  late final TextEditingController _direccionController;

  List<Categoria> _categorias = [];
  String? _categoriaId;
  bool _cargandoCategorias = true;

  late bool _isActive;
  late double _calificacion;
  late int _numResenas;
  late LatLng _coordenadas;
  late final MapController _mapController;
  bool _isSaving = false;
  List<String> _imagenes = [];

  String? _nombreError;
  String? _precioError;
  String? _contactoError;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurante;

    _nombreController = TextEditingController(
      text: r?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: r?.descripcion ?? '',
    );
    _horarioController = TextEditingController(
      text: r?.horarioAtencion ?? '',
    );
    _precioRefController = TextEditingController(
      text: r?.precioReferencial != null
          ? r!.precioReferencial.toString()
          : '',
    );
    final rawContacto = r?.contacto ?? '';
    final digitsContacto = rawContacto.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanContacto = (digitsContacto.startsWith('591') && digitsContacto.length == 11)
        ? digitsContacto.substring(3)
        : (digitsContacto.length > 8 ? digitsContacto.substring(0, 8) : digitsContacto);

    _contactoController = TextEditingController(
      text: cleanContacto,
    );
    _direccionController = TextEditingController(
      text: r?.direccionReferencia ?? '',
    );

    _categoriaId = r?.categoriaId;

    _isActive = r?.activo ?? true;
    _calificacion = (r != null && r.calificacionPromedio > 0)
        ? r.calificacionPromedio.toDouble()
        : 0.0;
    _numResenas = 0;

    _coordenadas = LatLng(
      r?.latitud ?? -18.0388,
      r?.longitud ?? -64.5283,
    );

    _imagenes = List.of(r?.imagenes ?? const <String>[]);

    _mapController = MapController();
    _nombreController.addListener(() {
      setState(() {});
    });
    _contactoController.addListener(() {
      if (_contactoError != null) setState(() => _contactoError = null);
    });
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final repo = context.read<CategoriaRepository>();
      final categorias = await repo.fetchByEntidad('restaurante');
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _cargandoCategorias = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _cargandoCategorias = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las categorías: $error')),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _horarioController.dispose();
    _precioRefController.dispose();
    _contactoController.dispose();
    _direccionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _mostrarDialogoNuevoTipo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nuevo tipo de comida',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0C3D28)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Pizzería, Comida oriental',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF26674B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              Navigator.pop(ctx);
              if (text.isEmpty) return;

              try {
                final repo = context.read<CategoriaRepository>();
                final categoria = await repo.create(entidad: 'restaurante', nombre: text);
                if (!mounted) return;
                setState(() {
                  _categorias = [..._categorias, categoria];
                  _categoriaId = categoria.id;
                });
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo crear la categoría: $error')),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  bool _validarFormulario() {
    setState(() {
      _nombreError = null;
      _precioError = null;
      _contactoError = null;
    });

    final nombre = _nombreController.text.trim();
    bool valido = true;

    if (nombre.isEmpty) {
      setState(() => _nombreError = 'El nombre del restaurante es obligatorio.');
      valido = false;
    } else if (nombre.length < 3) {
      setState(() => _nombreError = 'El nombre debe tener al menos 3 caracteres.');
      valido = false;
    } else if (nombre.length > 120) {
      setState(() => _nombreError = 'El nombre no puede superar los 120 caracteres.');
      valido = false;
    } else if (!RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]').hasMatch(nombre)) {
      setState(() => _nombreError = 'El nombre debe contener al menos una letra.');
      valido = false;
    }

    final pStr = _precioRefController.text.trim();
    if (pStr.isNotEmpty) {
      final cleaned = pStr.replaceAll(RegExp(r'[^0-9.]'), '');
      final pVal = num.tryParse(cleaned);
      if (cleaned.isNotEmpty && (pVal == null || pVal < 0)) {
        setState(() => _precioError = 'El precio debe ser mayor o igual a 0.');
        valido = false;
      }
    }

    final contacto = _contactoController.text.trim();
    if (contacto.isNotEmpty) {
      if (!RegExp(r'^\d+$').hasMatch(contacto)) {
        setState(() => _contactoError = 'Solo se permiten números.');
        valido = false;
      } else if (!RegExp(r'^[67]').hasMatch(contacto)) {
        setState(() => _contactoError = 'Debe comenzar con 6 o 7 (celular Bolivia).');
        valido = false;
      } else if (contacto.length != 8) {
        setState(() => _contactoError = 'Debe tener exactamente 8 dígitos.');
        valido = false;
      }
    }

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un tipo de comida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      valido = false;
    }

    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrige los errores en el formulario.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return valido;
  }

  Future<void> _guardarCambios() async {
    if (!_validarFormulario()) return;

    final nombre = _nombreController.text.trim();

    setState(() => _isSaving = true);

    try {
      final precioRaw = _precioRefController.text.trim();
      final num? precio = num.tryParse(precioRaw.replaceAll(RegExp(r'[^0-9.]'), ''));

      final updatedRestaurante = (widget.restaurante ??
              const Restaurante(
                nombre: '',
              ))
          .copyWith(
        nombre: nombre,
        categoriaId: _categoriaId,
        descripcion: _descripcionController.text.trim(),
        imagenes: _imagenes,
        horarioAtencion: _horarioController.text.trim().isNotEmpty
            ? _horarioController.text.trim()
            : null,
        precioReferencial: precio,
        contacto: _contactoController.text.trim().isNotEmpty
            ? _contactoController.text.trim()
            : null,
        direccionReferencia: _direccionController.text.trim().isNotEmpty
            ? _direccionController.text.trim()
            : null,
        calificacionPromedio: _calificacion,
        activo: _isActive,
        latitud: _coordenadas.latitude,
        longitud: _coordenadas.longitude,
      );

      final repo = context.read<RestauranteRepository>();

      if (widget.restaurante != null && widget.restaurante!.id != null) {
        await repo.update(updatedRestaurante);
      } else {
        await repo.create(updatedRestaurante);
      }

      if (!mounted) return;
      Navigator.pop(context, updatedRestaurante);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar restaurante: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nombreController.text.trim().isNotEmpty
        ? _nombreController.text.trim()
        : 'Restaurante';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            _buildTopBar(displayName),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Formulario scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo 1: Nombre del restaurante
                    _buildNombreField(),
                    const SizedBox(height: 20),

                    // Campo 2: Tipo de comida
                    _buildTipoComidaSelector(),
                    const SizedBox(height: 20),

                    // Campo 3: Descripción
                    _buildDescripcionField(),
                    const SizedBox(height: 20),

                    // Campo 4: Horario de atención y Precio referencial (Dos columnas)
                    _buildHorarioPrecioRow(),
                    const SizedBox(height: 20),

                    // Campo 5: Contacto
                    _buildContactoField(),
                    const SizedBox(height: 22),

                    // Campo 6: Calificación promedio
                    _buildCalificacionCard(),
                    const SizedBox(height: 22),

                    // Campo 7: Ubicación (Mini mapa)
                    _buildUbicacionSection(),
                    const SizedBox(height: 22),

                    // Campo 8: Imágenes
                    _buildImagenesSection(),
                    const SizedBox(height: 22),

                    // Campo 9: Estado del registro (Switch)
                    _buildEstadoRegistroCard(),
                  ],
                ),
              ),
            ),

            // Barra inferior con Cancelar y Guardar cambios
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurantes · $displayName',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Editar restaurante',
                  style: TextStyle(
                    color: Color(0xFF0C3D28),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false, bool isOptional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (isOptional) ...[
          const SizedBox(width: 6),
          const Text(
            '(Opcional)',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputContainer({
    required Widget child,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? const Color(0xFFDC2626) : Colors.grey.shade300,
              width: errorText != null ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: child,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNombreField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nombre del restaurante', isRequired: true),
        const SizedBox(height: 8),
        _buildInputContainer(
          errorText: _nombreError,
          child: TextField(
            controller: _nombreController,
            onChanged: (_) {
              if (_nombreError != null) setState(() => _nombreError = null);
            },
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoComidaSelector() {
    if (_cargandoCategorias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF26674B)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tipo de comida', isRequired: true),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._categorias.map((cat) {
                final isSelected = _categoriaId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _categoriaId = cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF26674B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF26674B) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat.nombre,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Botón + Nueva
              GestureDetector(
                onTap: _mostrarDialogoNuevoTipo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    '+ Nueva',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescripcionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Descripción', isOptional: true),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _descripcionController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF374151), height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioPrecioRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horario de atención
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Horario de atención', isOptional: true),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _horarioController,
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Precio referencial
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Precio ref. (Bs)', isOptional: true),
              const SizedBox(height: 8),
              _buildInputContainer(
                errorText: _precioError,
                child: TextField(
                  controller: _precioRefController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_precioError != null) setState(() => _precioError = null);
                  },
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactoField() {
    final hasError = _contactoError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Contacto', isOptional: true),
            Text(
              '8 dígitos · inicia con 6 o 7',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFDC2626) : Colors.grey.shade300,
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.phone_android,
                size: 18,
                color: hasError ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _contactoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                  decoration: const InputDecoration(
                    hintText: 'Ej. 71234567 o 61234567',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _contactoError!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildCalificacionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Calificación promedio', isOptional: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7EBE1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                _calificacion.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($_numResenas reseñas)',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Se calcula automáticamente a partir de las reseñas de los turistas; no es editable.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Future<void> _abrirMapaCompleto() async {
    final nuevaUbicacion = await FullscreenLocationPicker.pick(
      context: context,
      initialLocation: _coordenadas,
      title: 'Ubicación del restaurante',
    );
    if (nuevaUbicacion != null && mounted) {
      setState(() => _coordenadas = nuevaUbicacion);
      _mapController.move(nuevaUbicacion, 14.5);
    }
  }

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Ubicación interactiva', isOptional: true),
            TextButton.icon(
              onPressed: _abrirMapaCompleto,
              icon: const Icon(Icons.open_in_full_rounded, size: 15, color: Color(0xFF26674B)),
              label: const Text(
                'Ampliar mapa',
                style: TextStyle(
                  color: Color(0xFF26674B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFE5EFEA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _coordenadas,
                  initialZoom: 14.5,
                  onTap: (tapPosition, point) {
                    setState(() => _coordenadas = point);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ubicación fijada: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'bo.edu.uajms.proyecto_final_360',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _coordenadas,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF26674B),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 2,
                  shadowColor: Colors.black38,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _abrirMapaCompleto,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 16, color: Color(0xFF26674B)),
                          SizedBox(width: 3),
                          Text(
                            'Ampliar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF26674B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : 'Comarapa'} · ${_coordenadas.latitude.toStringAsFixed(4)}, ${_coordenadas.longitude.toStringAsFixed(4)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenesSection() {
    return ImagenPickerField(
      imagenes: _imagenes,
      carpeta: 'restaurantes',
      onChanged: (lista) => setState(() => _imagenes = lista),
    );
  }

  Widget _buildEstadoRegistroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado del registro',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isActive
                      ? 'Activo · visible en la app para los turistas.'
                      : 'Inactivo · oculto temporalmente en la app.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF26674B),
            onChanged: (val) => setState(() => _isActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // Botón Cancelar
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1F2937),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Botón Guardar cambios
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26674B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
