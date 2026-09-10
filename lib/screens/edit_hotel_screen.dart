import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/hotel.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/hotel_repository.dart';
import '../widgets/imagen_picker_field.dart';
import '../widgets/fullscreen_location_picker.dart';

class EditHotelScreen extends StatefulWidget {
  final Hotel? hotel;

  const EditHotelScreen({
    super.key,
    this.hotel,
  });

  @override
  State<EditHotelScreen> createState() => _EditHotelScreenState();
}

class _EditHotelScreenState extends State<EditHotelScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioDesdeController;
  late final TextEditingController _precioHastaController;
  late final TextEditingController _contactoController;
  late final TextEditingController _direccionController;

  List<Categoria> _categorias = [];
  String? _categoriaId;
  bool _cargandoCategorias = true;

  final List<String> _amenidades = ['Wifi', 'Parqueo', 'Desayuno', 'Fogata'];
  final Set<String> _amenidadesSeleccionadas = {'Wifi', 'Parqueo', 'Desayuno'};

  late bool _isActive;
  late double _calificacion;
  late int _numResenas;
  late LatLng _coordenadas;
  late final MapController _mapController;
  bool _isSaving = false;
  List<String> _imagenes = [];

  String? _nombreError;
  String? _precioMinError;
  String? _precioMaxError;
  String? _contactoError;

  @override
  void initState() {
    super.initState();
    final h = widget.hotel;

    _nombreController = TextEditingController(
      text: h?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: h?.descripcion ?? '',
    );
    _precioDesdeController = TextEditingController(
      text: h?.precioMin != null ? h!.precioMin!.toInt().toString() : '',
    );
    _precioHastaController = TextEditingController(
      text: h?.precioMax != null ? h!.precioMax!.toInt().toString() : '',
    );
    final rawContacto = h?.contactoReservas ?? '';
    final digitsContacto = rawContacto.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanContacto = (digitsContacto.startsWith('591') && digitsContacto.length == 11)
        ? digitsContacto.substring(3)
        : (digitsContacto.length > 8 ? digitsContacto.substring(0, 8) : digitsContacto);

    _contactoController = TextEditingController(
      text: cleanContacto,
    );
    _direccionController = TextEditingController(
      text: h?.direccionReferencia ?? '',
    );

    _categoriaId = h?.categoriaId;

    if (h != null && h.servicios.isNotEmpty) {
      _amenidadesSeleccionadas.clear();
      for (final s in h.servicios) {
        if (!_amenidades.contains(s)) {
          _amenidades.add(s);
        }
        _amenidadesSeleccionadas.add(s);
      }
    }

    _isActive = h?.activo ?? true;
    _calificacion = (h != null && h.calificacionPromedio > 0)
        ? h.calificacionPromedio.toDouble()
        : 0.0;
    _numResenas = 0;

    _coordenadas = LatLng(
      h?.latitud ?? -18.0401,
      h?.longitud ?? -64.5276,
    );

    _imagenes = List.of(h?.imagenes ?? const <String>[]);

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
      final categorias = await repo.fetchByEntidad('hotel');
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

  Future<void> _addNewCategory() async {
    final textController = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Nueva categoría / Tipo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C3D28)),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ej. Hostal, Cabaña...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF26674B)),
              onPressed: () => Navigator.pop(dialogContext, textController.text.trim()),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (nombre == null || nombre.isEmpty || !mounted) return;

    try {
      final repo = context.read<CategoriaRepository>();
      final categoria = await repo.create(entidad: 'hotel', nombre: nombre);
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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioDesdeController.dispose();
    _precioHastaController.dispose();
    _contactoController.dispose();
    _direccionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  IconData _getAmenidadIcon(String amenidad) {
    final lower = amenidad.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('parqueo') || lower.contains('estacionamiento')) {
      return Icons.local_parking;
    }
    if (lower.contains('desayuno') || lower.contains('restaurante')) {
      return Icons.coffee_outlined;
    }
    if (lower.contains('fogata') || lower.contains('fuego')) {
      return Icons.local_fire_department_outlined;
    }
    if (lower.contains('piscina')) return Icons.pool;
    if (lower.contains('aire') || lower.contains('clima')) return Icons.ac_unit;
    return Icons.check_circle_outline;
  }

  void _mostrarDialogoNuevaAmenidad() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nueva amenidad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0C3D28)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Piscina, Aire acondicionado',
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
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (!_amenidades.contains(text)) {
                    _amenidades.add(text);
                  }
                  _amenidadesSeleccionadas.add(text);
                });
              }
              Navigator.pop(ctx);
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
      _precioMinError = null;
      _precioMaxError = null;
      _contactoError = null;
    });

    final nombre = _nombreController.text.trim();
    bool valido = true;

    if (nombre.isEmpty) {
      setState(() => _nombreError = 'El nombre del hotel es obligatorio.');
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

    num? pMin;
    final minStr = _precioDesdeController.text.trim();
    if (minStr.isNotEmpty) {
      pMin = num.tryParse(minStr);
      if (pMin == null || pMin < 0) {
        setState(() => _precioMinError = 'El precio debe ser mayor o igual a 0.');
        valido = false;
      }
    }

    num? pMax;
    final maxStr = _precioHastaController.text.trim();
    if (maxStr.isNotEmpty) {
      pMax = num.tryParse(maxStr);
      if (pMax == null || pMax < 0) {
        setState(() => _precioMaxError = 'El precio debe ser mayor o igual a 0.');
        valido = false;
      }
    }

    if (pMin != null && pMax != null && pMax < pMin) {
      setState(() => _precioMaxError = 'El precio hasta no puede ser menor que el precio desde.');
      valido = false;
    }

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un tipo de hospedaje.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      valido = false;
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

    final pMin = num.tryParse(_precioDesdeController.text.trim());
    final pMax = num.tryParse(_precioHastaController.text.trim());

    setState(() => _isSaving = true);

    try {
      final updatedHotel = (widget.hotel ?? const Hotel(nombre: '')).copyWith(
        nombre: nombre,
        categoriaId: _categoriaId,
        descripcion: _descripcionController.text.trim(),
        imagenes: _imagenes,
        precioMin: pMin,
        precioMax: pMax,
        contactoReservas: _contactoController.text.trim().isNotEmpty
            ? _contactoController.text.trim()
            : null,
        direccionReferencia: _direccionController.text.trim().isNotEmpty
            ? _direccionController.text.trim()
            : null,
        servicios: _amenidadesSeleccionadas.toList(),
        activo: _isActive,
        latitud: _coordenadas.latitude,
        longitud: _coordenadas.longitude,
      );

      final repo = context.read<HotelRepository>();

      if (widget.hotel != null && widget.hotel!.id != null) {
        await repo.update(updatedHotel);
      } else {
        await repo.create(updatedHotel);
      }

      if (!mounted) return;
      Navigator.pop(context, updatedHotel);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nombreController.text.trim().isNotEmpty
        ? _nombreController.text.trim()
        : 'Hotel';

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
                    // Campo 1: Nombre del hotel
                    _buildNombreField(),
                    const SizedBox(height: 20),

                    // Campo 2: Tipo de hospedaje (Hotel, Hostal, Cabaña, Camping)
                    _buildTipoSelector(),
                    const SizedBox(height: 20),

                    // Campo 3: Descripción
                    _buildDescripcionField(),
                    const SizedBox(height: 20),

                    // Campo 4: Precios (desde / hasta en Bs/noche)
                    _buildPreciosRow(),
                    const SizedBox(height: 20),

                    // Campo 5: Amenidades
                    _buildAmenidadesSection(),
                    const SizedBox(height: 20),

                    // Campo 6: Contacto
                    _buildContactoField(),
                    const SizedBox(height: 22),

                    // Campo 7: Calificación promedio
                    _buildCalificacionCard(),
                    const SizedBox(height: 22),

                    // Campo 8: Ubicación (Mini mapa)
                    _buildUbicacionSection(),
                    const SizedBox(height: 22),

                    // Campo 9: Imágenes
                    _buildImagenesSection(),
                    const SizedBox(height: 22),

                    // Campo 10: Estado del registro (Switch)
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
                  'Hoteles · $displayName',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Editar hotel',
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
        _buildLabel('Nombre del hotel', isRequired: true),
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

  Widget _buildTipoSelector() {
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
        _buildLabel('Tipo', isRequired: true),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._categorias.map((cat) {
              final isSelected = _categoriaId == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _categoriaId = cat.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
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
              );
            }),
            GestureDetector(
              onTap: _addNewCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  '+ Nueva',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ),
          ],
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

  Widget _buildPreciosRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precio desde
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Precio desde (Bs)', isOptional: true),
              const SizedBox(height: 8),
              _buildInputContainer(
                errorText: _precioMinError,
                child: TextField(
                  controller: _precioDesdeController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_precioMinError != null) setState(() => _precioMinError = null);
                  },
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
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

        // Precio hasta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Precio hasta (Bs)', isOptional: true),
              const SizedBox(height: 8),
              _buildInputContainer(
                errorText: _precioMaxError,
                child: TextField(
                  controller: _precioHastaController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_precioMaxError != null) setState(() => _precioMaxError = null);
                  },
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
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

  Widget _buildAmenidadesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Amenidades', isOptional: true),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._amenidades.map((amenidad) {
              final isSelected = _amenidadesSeleccionadas.contains(amenidad);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _amenidadesSeleccionadas.remove(amenidad);
                    } else {
                      _amenidadesSeleccionadas.add(amenidad);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF26674B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF26674B) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmenidadIcon(amenidad),
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenidad,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Botón + Nueva
            GestureDetector(
              onTap: _mostrarDialogoNuevaAmenidad,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
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
            _buildLabel('Contacto / Reservas', isOptional: true),
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
      title: 'Ubicación del hotel',
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

        // Mini mapa interactivo con FlutterMap
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
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF26674B),
                          size: 36,
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
        const SizedBox(height: 8),

        // Campo editable para la dirección o referencia
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _direccionController,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151)),
            decoration: const InputDecoration(
              hintText: 'Dirección o referencia del hotel',
              prefixIcon: Icon(Icons.place_outlined, size: 18, color: Color(0xFF6B7280)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
        const SizedBox(height: 5),

        // Subtítulo de coordenadas dinámicas
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
      carpeta: 'hoteles',
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
