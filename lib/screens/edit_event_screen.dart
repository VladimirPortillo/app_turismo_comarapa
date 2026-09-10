import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/evento.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/evento_repository.dart';
import '../widgets/imagen_picker_field.dart';
import '../widgets/fullscreen_location_picker.dart';

class EditEventScreen extends StatefulWidget {
  final Evento? evento;

  const EditEventScreen({
    super.key,
    this.evento,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _direccionController;

  List<Categoria> _categorias = [];
  String? _categoriaId;
  bool _cargandoCategorias = true;

  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  late String _periodicidad;
  final List<String> _periodicidades = ['Anual', 'Único'];

  late bool _isActive;
  late LatLng _coordenadas;
  late final MapController _mapController;
  bool _isSaving = false;
  List<String> _imagenes = [];

  String? _nombreError;
  String? _fechaError;

  @override
  void initState() {
    super.initState();
    final ev = widget.evento;

    _nombreController = TextEditingController(
      text: ev?.nombre ?? 'Feria del Durazno',
    );
    _descripcionController = TextEditingController(
      text: ev?.descripcion.isNotEmpty == true
          ? ev!.descripcion
          : 'La celebración agrícola más importante de Comarapa: productos derivados del durazno, música y gastronomía local...',
    );
    _direccionController = TextEditingController(
      text: 'Campo ferial, Comarapa',
    );

    _categoriaId = ev?.categoriaId;

    _fechaInicio = ev?.fechaInicio ?? DateTime(2027, 1, 15);
    _fechaFin = ev?.fechaFin ?? DateTime(2027, 1, 18);

    final per = ev?.periodicidad?.toLowerCase() ?? 'anual';
    _periodicidad = per == 'único' || per == 'unico' ? 'Único' : 'Anual';

    _isActive = ev?.activo ?? true;

    _coordenadas = LatLng(
      ev?.latitud ?? -18.0447,
      ev?.longitud ?? -64.5301,
    );

    _imagenes = List.of(ev?.imagenes ?? const <String>[]);

    _mapController = MapController();
    _nombreController.addListener(() {
      setState(() {});
    });
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final repo = context.read<CategoriaRepository>();
      final categorias = await repo.fetchByEntidad('evento');
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
    _direccionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _seleccionarFecha({required bool isInicio}) async {
    final initialDate = isInicio ? _fechaInicio : _fechaFin;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26674B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 3));
          }
        } else {
          _fechaFin = picked;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin;
          }
        }
        _fechaError = null;
      });
    }
  }

  void _mostrarDialogoNuevoTipo() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nuevo tipo de evento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0C3D28)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej: Festival, Encuentro',
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
                final categoria = await repo.create(entidad: 'evento', nombre: text);
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
      _fechaError = null;
    });

    final nombre = _nombreController.text.trim();
    bool valido = true;

    if (nombre.isEmpty) {
      setState(() => _nombreError = 'El nombre del evento es obligatorio.');
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

    if (_fechaFin.isBefore(_fechaInicio)) {
      setState(() => _fechaError = 'La fecha de fin no puede ser anterior a la fecha de inicio.');
      valido = false;
    }

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un tipo de evento.'),
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
      final updatedEvento = (widget.evento ??
              Evento(
                nombre: '',
                fechaInicio: DateTime.now(),
              ))
          .copyWith(
        nombre: nombre,
        categoriaId: _categoriaId,
        descripcion: _descripcionController.text.trim(),
        imagenes: _imagenes,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        periodicidad: _periodicidad.toLowerCase(),
        activo: _isActive,
        latitud: _coordenadas.latitude,
        longitud: _coordenadas.longitude,
      );

      final repo = context.read<EventoRepository>();

      if (widget.evento != null &&
          widget.evento!.id != null &&
          !widget.evento!.id!.startsWith('demo-')) {
        await repo.update(updatedEvento);
      } else if (widget.evento == null) {
        await repo.create(updatedEvento);
      }

      if (!mounted) return;
      Navigator.pop(context, updatedEvento);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar evento: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nombreController.text.trim().isNotEmpty
        ? _nombreController.text.trim()
        : 'Evento';

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
                    // Campo 1: Nombre del evento
                    _buildNombreField(),
                    const SizedBox(height: 20),

                    // Campo 2: Tipo de evento
                    _buildTipoSelector(),
                    const SizedBox(height: 20),

                    // Campo 3: Descripción
                    _buildDescripcionField(),
                    const SizedBox(height: 20),

                    // Campo 4: Fechas (Inicio y Fin en dos columnas)
                    _buildFechasRow(),
                    const SizedBox(height: 20),

                    // Campo 5: Periodicidad (Anual / Único)
                    _buildPeriodicidadSelector(),
                    const SizedBox(height: 22),

                    // Campo 6: Ubicación (Mini mapa)
                    _buildUbicacionSection(),
                    const SizedBox(height: 22),

                    // Campo 7: Imágenes
                    _buildImagenesSection(),
                    const SizedBox(height: 22),

                    // Campo 8: Estado del registro (Switch)
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
                  'Eventos · $displayName',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Editar evento',
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
        _buildLabel('Nombre del evento', isRequired: true),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _buildFechasRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fecha de inicio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Fecha de inicio', isRequired: true),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _seleccionarFecha(isInicio: true),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatearFecha(_fechaInicio),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Fecha de fin
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Fecha de fin', isOptional: true),
              const SizedBox(height: 8),
              _buildInputContainer(
                errorText: _fechaError,
                child: GestureDetector(
                  onTap: () => _seleccionarFecha(isInicio: false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatearFecha(_fechaFin),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPeriodicidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Periodicidad', isOptional: true),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F4),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: _periodicidades.map((opcion) {
              final isSelected = _periodicidad == opcion;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _periodicidad = opcion),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26674B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opcion,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirMapaCompleto() async {
    final nuevaUbicacion = await FullscreenLocationPicker.pick(
      context: context,
      initialLocation: _coordenadas,
      title: 'Ubicación del evento',
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
      carpeta: 'eventos',
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
