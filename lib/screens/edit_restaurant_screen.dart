import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/restaurante.dart';
import '../repositories/restaurante_repository.dart';

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

  late String _tipoSeleccionado;
  final List<String> _tiposDisponibles = ['Comida típica', 'Parrilla', 'Café & repostería'];

  late bool _isActive;
  late double _calificacion;
  late int _numResenas;
  late LatLng _coordenadas;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurante;

    _nombreController = TextEditingController(
      text: r?.nombre ?? 'El Fogón Comarapeño',
    );
    _descripcionController = TextEditingController(
      text: r?.descripcion.isNotEmpty == true
          ? r!.descripcion
          : 'Cocina tradicional comarapeña: picantes, pique macho y platos a base de durazno, en un ambiente familiar...',
    );
    _horarioController = TextEditingController(
      text: r?.horarioAtencion?.isNotEmpty == true
          ? r!.horarioAtencion!
          : '12:00 - 21:00',
    );
    _precioRefController = TextEditingController(
      text: r?.precioReferencial != null
          ? 'Bs ${r!.precioReferencial}'
          : 'Bs 35 - 60',
    );
    _contactoController = TextEditingController(
      text: r?.contacto?.isNotEmpty == true
          ? r!.contacto!
          : '+591 3 936 1120',
    );
    _direccionController = TextEditingController(
      text: r?.direccionReferencia?.isNotEmpty == true
          ? r!.direccionReferencia!
          : 'A media cuadra de la plaza principal, Comarapa',
    );

    _tipoSeleccionado = r?.categoriaNombre ?? 'Comida típica';
    if (!_tiposDisponibles.contains(_tipoSeleccionado)) {
      _tiposDisponibles.insert(0, _tipoSeleccionado);
    }

    _isActive = r?.activo ?? true;
    _calificacion = (r != null && r.calificacionPromedio > 0)
        ? r.calificacionPromedio.toDouble()
        : 4.8;
    _numResenas = 32;

    _coordenadas = LatLng(
      r?.latitud ?? -18.0388,
      r?.longitud ?? -64.5283,
    );

    _nombreController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _horarioController.dispose();
    _precioRefController.dispose();
    _contactoController.dispose();
    _direccionController.dispose();
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
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (!_tiposDisponibles.contains(text)) {
                    _tiposDisponibles.add(text);
                  }
                  _tipoSeleccionado = text;
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

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del restaurante no puede estar vacío.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedRestaurante = (widget.restaurante ??
              const Restaurante(
                nombre: '',
              ))
          .copyWith(
        nombre: nombre,
        categoriaNombre: _tipoSeleccionado,
        descripcion: _descripcionController.text.trim(),
        horarioAtencion: _horarioController.text.trim(),
        contacto: _contactoController.text.trim(),
        direccionReferencia: _direccionController.text.trim(),
        calificacionPromedio: _calificacion,
        activo: _isActive,
        latitud: _coordenadas.latitude,
        longitud: _coordenadas.longitude,
      );

      final repo = context.read<RestauranteRepository>();

      if (widget.restaurante != null &&
          widget.restaurante!.id != null &&
          !widget.restaurante!.id!.startsWith('demo-')) {
        await repo.update(updatedRestaurante);
      } else if (widget.restaurante == null) {
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

  Widget _buildNombreField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre del restaurante',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: _nombreController,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de comida',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._tiposDisponibles.map((tipo) {
                final isSelected = _tipoSeleccionado == tipo;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _tipoSeleccionado = tipo),
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
                        tipo,
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
        const Text(
          'Descripción',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
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
      children: [
        // Horario de atención
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Horario de atención',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
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
              const Text(
                'Precio referencial',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _precioRefController,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _contactoController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalificacionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificación promedio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
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

  Widget _buildUbicacionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFE5EFEA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _coordenadas,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
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
        ),
        const SizedBox(height: 6),
        Text(
          '${_direccionController.text.trim()} · ${_coordenadas.latitude.toStringAsFixed(4)}, ${_coordenadas.longitude.toStringAsFixed(4)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenesSection() {
    final List<Color> sampleColors = [
      const Color(0xFFB57834),
      const Color(0xFFD39B54),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imágenes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Área de subida dashed
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.file_upload_outlined, size: 26, color: Color(0xFF4B5563)),
              SizedBox(height: 6),
              Text(
                'Tomar foto o subir desde la galería',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Miniaturas de fotos
        Row(
          children: List.generate(2, (index) {
            final isPrincipal = index == 0;
            return Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: sampleColors[index],
                borderRadius: BorderRadius.circular(14),
              ),
              child: isPrincipal
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(6),
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
                    )
                  : null,
            );
          }),
        ),
      ],
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
