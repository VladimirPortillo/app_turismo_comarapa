import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/actividad.dart';
import '../models/categoria.dart';
import '../models/gastronomia_item.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/turismo_tipo.dart';
import '../repositories/actividad_repository.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/gastronomia_repository.dart';
import '../repositories/hotel_repository.dart';
import '../repositories/lugar_repository.dart';
import '../widgets/imagen_picker_field.dart';

const Color _kPrimary = Color(0xFF1B5A3F);
const Color _kAccent = Color(0xFF2A7353);
const Color _kBg = Color(0xFFFAF9F6);

/// Formulario único de creación / edición para los 4 módulos del MVP
/// (Lugares, Actividades, Gastronomía, Hoteles). Recibe la entidad ya
/// tipada correspondiente; si todas vienen null, es un registro nuevo.
class EditPlaceScreen extends StatefulWidget {
  const EditPlaceScreen({
    super.key,
    required this.tipo,
    this.lugar,
    this.actividad,
    this.hotel,
    this.gastronomia,
  });

  final TurismoTipo tipo;
  final Lugar? lugar;
  final Actividad? actividad;
  final Hotel? hotel;
  final GastronomiaItem? gastronomia;

  bool get esNuevo =>
      lugar == null && actividad == null && hotel == null && gastronomia == null;

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  List<String> _imagenesSeleccionadas = [];

  // lugares
  final _tiempoVisitaController = TextEditingController();
  final _costoEntradaController = TextEditingController();
  final _mejorEpocaController = TextEditingController();
  final _direccionController = TextEditingController();

  // actividades
  final _duracionController = TextEditingController();
  final _precioRefController = TextEditingController();
  final _operadorController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _temporadaController = TextEditingController();

  // hoteles
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();
  final _serviciosController = TextEditingController();
  final _contactoReservasController = TextEditingController();

  String _dificultad = 'facil';
  bool _activo = true;
  LatLng? _ubicacion;
  late final MapController _mapController;

  List<Categoria> _categorias = [];
  String? _categoriaId;
  bool _cargandoCategorias = true;
  bool _guardando = false;

  bool get _usaUbicacion =>
      widget.tipo == TurismoTipo.lugar ||
      widget.tipo == TurismoTipo.actividad ||
      widget.tipo == TurismoTipo.hotel;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _cargarValoresIniciales();
    _cargarCategorias();
  }

  void _cargarValoresIniciales() {
    switch (widget.tipo) {
      case TurismoTipo.lugar:
        final l = widget.lugar;
        _nombreController.text = l?.nombre ?? '';
        _descripcionController.text = l?.descripcion ?? '';
        _imagenesSeleccionadas = List.of(l?.imagenes ?? const <String>[]);
        _dificultad = l?.dificultad ?? 'facil';
        _tiempoVisitaController.text = l?.tiempoVisitaMin?.toString() ?? '';
        _costoEntradaController.text =
            (l?.costoEntrada ?? 0) == 0 ? '' : l!.costoEntrada.toString();
        _mejorEpocaController.text = l?.mejorEpoca ?? '';
        _direccionController.text = l?.direccionReferencia ?? '';
        _activo = l?.activo ?? true;
        _categoriaId = l?.categoriaId;
        _ubicacion = (l?.latitud != null && l?.longitud != null)
            ? LatLng(l!.latitud!, l.longitud!)
            : const LatLng(-17.9145, -64.4818);
        break;
      case TurismoTipo.actividad:
        final a = widget.actividad;
        _nombreController.text = a?.nombre ?? '';
        _descripcionController.text = a?.descripcion ?? '';
        _imagenesSeleccionadas = List.of(a?.imagenes ?? const <String>[]);
        _dificultad = a?.dificultad ?? 'facil';
        _duracionController.text = a?.duracionMin?.toString() ?? '';
        _precioRefController.text = a?.precioReferencial?.toString() ?? '';
        _operadorController.text = a?.operadorContacto ?? '';
        _capacidadController.text = a?.capacidadMaxima?.toString() ?? '';
        _temporadaController.text = a?.temporada ?? '';
        _activo = a?.activo ?? true;
        _categoriaId = a?.categoriaId;
        _ubicacion = (a?.latitud != null && a?.longitud != null)
            ? LatLng(a!.latitud!, a.longitud!)
            : const LatLng(-17.9145, -64.4818);
        break;
      case TurismoTipo.hotel:
        final h = widget.hotel;
        _nombreController.text = h?.nombre ?? '';
        _descripcionController.text = h?.descripcion ?? '';
        _imagenesSeleccionadas = List.of(h?.imagenes ?? const <String>[]);
        _direccionController.text = h?.direccionReferencia ?? '';
        _precioMinController.text = h?.precioMin?.toString() ?? '';
        _precioMaxController.text = h?.precioMax?.toString() ?? '';
        _serviciosController.text = h?.servicios.join(', ') ?? '';
        _contactoReservasController.text = h?.contactoReservas ?? '';
        _activo = h?.activo ?? true;
        _categoriaId = h?.categoriaId;
        _ubicacion = (h?.latitud != null && h?.longitud != null)
            ? LatLng(h!.latitud!, h.longitud!)
            : const LatLng(-17.9145, -64.4818);
        break;
      case TurismoTipo.gastronomia:
        final g = widget.gastronomia;
        _nombreController.text = g?.nombre ?? '';
        _descripcionController.text = g?.descripcion ?? '';
        _imagenesSeleccionadas = List.of(g?.imagenes ?? const <String>[]);
        _temporadaController.text = g?.temporada ?? '';
        _precioRefController.text = g?.precioReferencial?.toString() ?? '';
        _activo = g?.activo ?? true;
        _categoriaId = g?.categoriaId;
        break;
      case TurismoTipo.evento:
        // Los eventos se gestionan desde AdminEventsScreen, no desde aquí.
        break;
      case TurismoTipo.restaurante:
        // Los restaurantes se gestionan desde AdminRestaurantsScreen, no desde aquí.
        break;
    }
  }

  Future<void> _cargarCategorias() async {
    try {
      final repo = context.read<CategoriaRepository>();
      final categorias = await repo.fetchByEntidad(widget.tipo.entidad);
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        if (_categoriaId != null && categorias.every((c) => c.id != _categoriaId)) {
          // La categoría guardada ya no está activa; se conserva seleccionada
          // igual para no perder el dato hasta que el usuario la cambie.
        }
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
    _tiempoVisitaController.dispose();
    _costoEntradaController.dispose();
    _mejorEpocaController.dispose();
    _direccionController.dispose();
    _duracionController.dispose();
    _precioRefController.dispose();
    _operadorController.dispose();
    _capacidadController.dispose();
    _temporadaController.dispose();
    _precioMinController.dispose();
    _precioMaxController.dispose();
    _serviciosController.dispose();
    _contactoReservasController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory() async {
    final textController = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _kBg,
          title: const Text(
            'Nueva categoría / Tipo',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: Color(0xFF0C3D28)),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej. Mirador, Cascada...',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _kPrimary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
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
      final categoria = await repo.create(entidad: widget.tipo.entidad, nombre: nombre);
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

  Future<void> _save() async {
    final nombre = _nombreController.text.trim();
    if (nombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 3 caracteres.')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      switch (widget.tipo) {
        case TurismoTipo.lugar:
          await _guardarLugar(nombre);
          break;
        case TurismoTipo.actividad:
          await _guardarActividad(nombre);
          break;
        case TurismoTipo.hotel:
          await _guardarHotel(nombre);
          break;
        case TurismoTipo.gastronomia:
          await _guardarGastronomia(nombre);
          break;
        case TurismoTipo.evento:
          // Los eventos se gestionan desde AdminEventsScreen, no desde aquí.
          break;
        case TurismoTipo.restaurante:
          // Los restaurantes se gestionan desde AdminRestaurantsScreen, no desde aquí.
          break;
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _guardarLugar(String nombre) async {
    final lugar = Lugar(
      id: widget.lugar?.id,
      categoriaId: _categoriaId,
      nombre: nombre,
      descripcion: _descripcionController.text,
      imagenes: _imagenesSeleccionadas,
      latitud: _ubicacion?.latitude,
      longitud: _ubicacion?.longitude,
      direccionReferencia: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      dificultad: _dificultad,
      tiempoVisitaMin: int.tryParse(_tiempoVisitaController.text.trim()),
      costoEntrada: num.tryParse(_costoEntradaController.text.trim()) ?? 0,
      mejorEpoca: _mejorEpocaController.text.trim().isEmpty
          ? null
          : _mejorEpocaController.text.trim(),
      activo: _activo,
    );

    final repo = context.read<LugarRepository>();
    if (widget.esNuevo) {
      await repo.create(lugar);
    } else {
      await repo.update(lugar);
    }
  }

  Future<void> _guardarActividad(String nombre) async {
    final actividad = Actividad(
      id: widget.actividad?.id,
      categoriaId: _categoriaId,
      nombre: nombre,
      descripcion: _descripcionController.text,
      imagenes: _imagenesSeleccionadas,
      latitud: _ubicacion?.latitude,
      longitud: _ubicacion?.longitude,
      dificultad: _dificultad,
      duracionMin: int.tryParse(_duracionController.text.trim()),
      precioReferencial: num.tryParse(_precioRefController.text.trim()),
      operadorContacto: _operadorController.text.trim().isEmpty
          ? null
          : _operadorController.text.trim(),
      capacidadMaxima: int.tryParse(_capacidadController.text.trim()),
      temporada: _temporadaController.text.trim().isEmpty
          ? null
          : _temporadaController.text.trim(),
      activo: _activo,
    );

    final repo = context.read<ActividadRepository>();
    if (widget.esNuevo) {
      await repo.create(actividad);
    } else {
      await repo.update(actividad);
    }
  }

  Future<void> _guardarHotel(String nombre) async {
    final servicios = _serviciosController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final hotel = Hotel(
      id: widget.hotel?.id,
      categoriaId: _categoriaId,
      nombre: nombre,
      descripcion: _descripcionController.text,
      imagenes: _imagenesSeleccionadas,
      latitud: _ubicacion?.latitude,
      longitud: _ubicacion?.longitude,
      direccionReferencia: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      precioMin: num.tryParse(_precioMinController.text.trim()),
      precioMax: num.tryParse(_precioMaxController.text.trim()),
      servicios: servicios,
      contactoReservas: _contactoReservasController.text.trim().isEmpty
          ? null
          : _contactoReservasController.text.trim(),
      activo: _activo,
    );

    final repo = context.read<HotelRepository>();
    if (widget.esNuevo) {
      await repo.create(hotel);
    } else {
      await repo.update(hotel);
    }
  }

  Future<void> _guardarGastronomia(String nombre) async {
    final item = GastronomiaItem(
      id: widget.gastronomia?.id,
      categoriaId: _categoriaId,
      nombre: nombre,
      descripcion: _descripcionController.text,
      imagenes: _imagenesSeleccionadas,
      temporada: _temporadaController.text.trim().isEmpty
          ? null
          : _temporadaController.text.trim(),
      precioReferencial: num.tryParse(_precioRefController.text.trim()),
      activo: _activo,
    );

    final repo = context.read<GastronomiaRepository>();
    if (widget.esNuevo) {
      await repo.create(item);
    } else {
      await repo.update(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nombre'),
                    _buildTextField(_nombreController, hintText: 'Nombre'),
                    const SizedBox(height: 20),

                    _buildLabel('Categoría / Tipo'),
                    _buildCategoryChips(),
                    const SizedBox(height: 20),

                    _buildLabel('Descripción'),
                    _buildTextField(_descripcionController, hintText: 'Descripción...', maxLines: 4),
                    const SizedBox(height: 20),

                    ImagenPickerField(
                      imagenes: _imagenesSeleccionadas,
                      carpeta: widget.tipo.entidad,
                      onChanged: (lista) => setState(() => _imagenesSeleccionadas = lista),
                    ),
                    const SizedBox(height: 20),

                    ..._buildCamposEspecificos(),

                    _buildLabel('Estado'),
                    _buildActivoSwitch(),
                    const SizedBox(height: 20),

                    if (_usaUbicacion) ...[
                      _buildLabel('Ubicación'),
                      _buildMapSelector(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCamposEspecificos() {
    switch (widget.tipo) {
      case TurismoTipo.lugar:
        return [
          _buildLabel('Dificultad'),
          _buildDifficultySelector(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tiempo estimado (min)'),
                    _buildTextField(_tiempoVisitaController, hintText: 'Ej. 120', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Costo de entrada (Bs.)'),
                    _buildTextField(_costoEntradaController, hintText: 'Ej. 10', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Mejor época para visitar'),
          _buildTextField(_mejorEpocaController, hintText: 'Ej. Abril – Octubre'),
          const SizedBox(height: 20),
          _buildLabel('Dirección de referencia'),
          _buildTextField(_direccionController, hintText: 'Ej. A 3 km del centro'),
          const SizedBox(height: 20),
        ];
      case TurismoTipo.actividad:
        return [
          _buildLabel('Dificultad'),
          _buildDifficultySelector(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Duración (min)'),
                    _buildTextField(_duracionController, hintText: 'Ej. 150', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Precio referencial (Bs.)'),
                    _buildTextField(_precioRefController, hintText: 'Ej. 30', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Operador / contacto'),
          _buildTextField(_operadorController, hintText: 'Guía u operador responsable'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Capacidad máxima'),
                    _buildTextField(_capacidadController, hintText: 'Ej. 15', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Temporada'),
                    _buildTextField(_temporadaController, hintText: 'Ej. Octubre – Marzo'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ];
      case TurismoTipo.hotel:
        return [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Precio mínimo (Bs.)'),
                    _buildTextField(_precioMinController, hintText: 'Ej. 80', keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Precio máximo (Bs.)'),
                    _buildTextField(_precioMaxController, hintText: 'Ej. 150', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Servicios (separados por coma)'),
          _buildTextField(_serviciosController, hintText: 'Wifi, Parqueo, Desayuno'),
          const SizedBox(height: 20),
          _buildLabel('Contacto para reservas'),
          _buildTextField(_contactoReservasController, hintText: 'Teléfono / WhatsApp'),
          const SizedBox(height: 20),
          _buildLabel('Dirección de referencia'),
          _buildTextField(_direccionController, hintText: 'Ej. Media cuadra de la plaza'),
          const SizedBox(height: 20),
        ];
      case TurismoTipo.gastronomia:
        return [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Temporada'),
                    _buildTextField(_temporadaController, hintText: 'Ej. Temporada de durazno'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Precio referencial (Bs.)'),
                    _buildTextField(_precioRefController, hintText: 'Ej. 15', keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ];
      case TurismoTipo.evento:
        // Los eventos se gestionan desde AdminEventsScreen, no desde aquí.
        return const <Widget>[];
      case TurismoTipo.restaurante:
        // Los restaurantes se gestionan desde AdminRestaurantsScreen, no desde aquí.
        return const <Widget>[];
    }
  }

  Widget _buildHeader() {
    final titulo = widget.esNuevo ? 'Nuevo · ${widget.tipo.etiqueta}' : 'Editar · ${widget.tipo.etiqueta}';
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
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
              ),
              child: const Icon(Icons.chevron_left, color: Colors.black87, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF0C3D28),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'serif',
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_cargandoCategorias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._categorias.map((cat) {
          final isSelected = _categoriaId == cat.id;
          return ChoiceChip(
            label: Text(
              cat.nombre,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _categoriaId = cat.id);
              }
            },
            selectedColor: _kAccent,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? _kAccent : Colors.grey.shade200),
            ),
            showCheckmark: false,
          );
        }),
        GestureDetector(
          onTap: _addNewCategory,
          child: CustomPaint(
            painter: DottedBorderPainter(color: Colors.grey.shade400, strokeWidth: 1, radius: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: Text(
                '+ Nueva',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF2F6F4), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: kNivelesDificultad.map((valor) {
          final isSelected = _dificultad == valor;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dificultad = valor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _kAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  dificultadLabel(valor),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4A6B5C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivoSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(_activo ? 'Activo (visible en la app)' : 'Inactivo (oculto, borrado lógico)'),
        activeThumbColor: _kPrimary,
        value: _activo,
        onChanged: (value) => setState(() => _activo = value),
      ),
    );
  }

  Widget _buildMapSelector() {
    final center = _ubicacion ?? const LatLng(-17.9145, -64.4818);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.5,
                onTap: (tapPosition, latLng) {
                  setState(() => _ubicacion = latLng);
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
                      point: center,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_on, size: 40, color: _kAccent),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Toca para ubicar el pin', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _guardando ? null : _save,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Guardar cambios',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja un borde punteado alrededor del botón "+ Nueva" categoría.
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
  }
}
