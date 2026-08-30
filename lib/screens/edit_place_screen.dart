import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'admin_home_screen.dart';

class EditPlaceScreen extends StatefulWidget {
  final AdminPlace place;

  const EditPlaceScreen({super.key, required this.place});

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _estimatedTimeController;
  late final TextEditingController _entryCostController;
  late final TextEditingController _bestSeasonController;

  late String _selectedCategory;
  late String _selectedDifficulty;
  late LatLng _currentLocation;
  late final MapController _mapController;

  final List<String> _categories = ['Natural', 'Arqueológico', 'Aventura'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _descriptionController = TextEditingController(text: widget.place.description ?? '');
    _estimatedTimeController = TextEditingController(text: widget.place.estimatedTime ?? '2 horas');
    _entryCostController = TextEditingController(text: widget.place.entryCost ?? 'Gratuito');
    _bestSeasonController = TextEditingController(text: widget.place.bestSeason ?? 'Abril – Octubre');

    _selectedCategory = widget.place.category;
    if (!_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory);
    }

    _selectedDifficulty = widget.place.difficulty ?? 'Fácil';
    _currentLocation = LatLng(widget.place.latitude ?? -17.9145, widget.place.longitude ?? -64.4818);
    _mapController = MapController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    _entryCostController.dispose();
    _bestSeasonController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _addNewCategory() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF9F6),
          title: const Text(
            'Nueva categoría / Tipo',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: Color(0xFF0C3D28)),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej. Mirador, Cascada...',
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1B5A3F))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5A3F)),
              onPressed: () {
                final newCat = textController.text.trim();
                if (newCat.isNotEmpty) {
                  setState(() {
                    if (!_categories.contains(newCat)) {
                      _categories.add(newCat);
                    }
                    _selectedCategory = newCat;
                  });
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del lugar no puede estar vacío.')),
      );
      return;
    }

    final updatedPlace = AdminPlace(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      mainCategory: widget.place.mainCategory,
      isActive: widget.place.isActive,
      description: _descriptionController.text.trim(),
      difficulty: _selectedDifficulty,
      estimatedTime: _estimatedTimeController.text.trim(),
      entryCost: _entryCostController.text.trim(),
      bestSeason: _bestSeasonController.text.trim(),
      latitude: _currentLocation.latitude,
      longitude: _currentLocation.longitude,
    );

    Navigator.pop(context, updatedPlace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
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
                    _buildLabel('Nombre del lugar'),
                    _buildTextField(_nameController, hintText: 'Nombre del lugar'),
                    const SizedBox(height: 20),

                    _buildLabel('Tipo'),
                    _buildCategoryChips(),
                    const SizedBox(height: 20),

                    _buildLabel('Descripción'),
                    _buildTextField(_descriptionController, hintText: 'Descripción del lugar...', maxLines: 4),
                    const SizedBox(height: 20),

                    _buildLabel('Dificultad'),
                    _buildDifficultySelector(),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tiempo estimado'),
                              _buildTextField(_estimatedTimeController, hintText: 'Ej. 2 horas'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Costo de entrada'),
                              _buildTextField(_entryCostController, hintText: 'Ej. Gratuito o 10 Bs.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Mejor época para visitar'),
                    _buildTextField(_bestSeasonController, hintText: 'Ej. Abril – Octubre'),
                    const SizedBox(height: 20),

                    _buildLabel('Ubicación'),
                    _buildMapSelector(),
                    const SizedBox(height: 24),
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

  Widget _buildHeader() {
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
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lugares · ${widget.place.name}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Editar lugar',
                  style: TextStyle(
                    color: Color(0xFF0C3D28),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontFamily: 'serif',
                    height: 1.1,
                  ),
                ),
              ],
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
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String hintText, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategory = cat;
                });
              }
            },
            selectedColor: const Color(0xFF2A7353),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2A7353) : Colors.grey.shade200,
              ),
            ),
            showCheckmark: false,
          );
        }),
        // Add dotted button "+ Nueva"
        GestureDetector(
          onTap: _addNewCategory,
          child: CustomPaint(
            painter: DottedBorderPainter(color: Colors.grey.shade400, strokeWidth: 1, radius: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+ Nueva',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = ['Fácil', 'Media', 'Difícil'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: difficulties.map((diff) {
          final isSelected = _selectedDifficulty == diff;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDifficulty = diff;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A7353) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  diff,
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

  Widget _buildMapSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13.5,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _currentLocation = latLng;
                  });
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
                      point: _currentLocation,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Color(0xFF2A7353),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Helper label overlay on map
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Toca para ubicar el pin',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
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
                backgroundColor: const Color(0xFF2A7353),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveChanges,
              child: const Text(
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

// Custom Painter to draw dashed/dotted borders around "+ Nueva"
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

    // Calculate dashed effect
    final dashWidth = 4.0;
    final dashSpace = 3.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = dashWidth;
        final Path extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += length + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.radius != radius;
  }
}
