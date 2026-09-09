import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resena.dart';
import '../repositories/resena_repository.dart';

/// Sección completa de reseñas y calificaciones (lista + formulario para
/// escribir una nueva) reutilizable en cualquier pantalla de detalle:
/// lugares, hoteles, restaurantes, actividades, gastronomía o eventos.
/// Carga y guarda contra la tabla `resenas` de Supabase usando [entidad]
/// (debe coincidir con el enum `entidad_resenable`) y [entidadId].
class ResenasSection extends StatefulWidget {
  const ResenasSection({
    super.key,
    required this.entidad,
    required this.entidadId,
    this.onResumenActualizado,
  });

  final String entidad;
  final String entidadId;

  /// Se llama con (promedio, total) cada vez que cambian las reseñas
  /// cargadas, para que la pantalla contenedora pueda mostrar un resumen
  /// (por ejemplo, la fila de estrellas junto al nombre del lugar).
  final void Function(double promedio, int total)? onResumenActualizado;

  @override
  State<ResenasSection> createState() => _ResenasSectionState();
}

class _ResenasSectionState extends State<ResenasSection> {
  List<Resena> _resenas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    try {
      final repo = context.read<ResenaRepository>();
      final resenas = await repo.fetchAprobadas(
        entidad: widget.entidad,
        entidadId: widget.entidadId,
      );
      if (!mounted) return;
      setState(() {
        _resenas = resenas;
        _cargando = false;
      });
      _notificarResumen();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _notificarResumen() {
    final callback = widget.onResumenActualizado;
    if (callback == null) return;
    final promedio = _resenas.isEmpty
        ? 0.0
        : _resenas.fold<int>(0, (acc, r) => acc + r.calificacion) /
              _resenas.length;
    callback(promedio, _resenas.length);
  }

  Future<void> _abrirFormularioResena() async {
    final nombreController = TextEditingController();
    final comentarioController = TextEditingController();
    int calificacionSeleccionada = 5;
    bool enviando = false;
    String? nombreError;
    String? comentarioError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            bool validarFormulario() {
              setSheetState(() {
                nombreError = null;
                comentarioError = null;
              });

              final nombre = nombreController.text.trim();
              final comentario = comentarioController.text.trim();
              bool valido = true;

              // 1. Campo Nombre:
              // Obligatorio, máx 50 caracteres, solo letras y espacios, mín 3 caracteres de letras
              final totalLetras = RegExp(
                r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]',
              ).allMatches(nombre).length;
              final soloLetrasYEspacios = RegExp(
                r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$',
              ).hasMatch(nombre);

              if (nombre.isEmpty) {
                setSheetState(() => nombreError = 'El nombre es obligatorio.');
                valido = false;
              } else if (nombre.length > 50) {
                setSheetState(
                  () => nombreError =
                      'El nombre no puede superar los 50 caracteres.',
                );
                valido = false;
              } else if (!soloLetrasYEspacios) {
                setSheetState(
                  () => nombreError =
                      'El nombre solo debe contener letras y espacios.',
                );
                valido = false;
              } else if (totalLetras < 3) {
                setSheetState(
                  () => nombreError =
                      'El nombre debe contener al menos 3 letras.',
                );
                valido = false;
              }

              // 2. Campo Comentario:
              // Opcional, pero si se escribe, máx 500 caracteres
              if (comentario.isNotEmpty && comentario.length > 500) {
                setSheetState(
                  () => comentarioError =
                      'El comentario no puede superar los 500 caracteres.',
                );
                valido = false;
              }

              return valido;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Escribir una reseña',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C3D28),
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final valor = i + 1;
                          return IconButton(
                            onPressed: () => setSheetState(
                              () => calificacionSeleccionada = valor,
                            ),
                            icon: Icon(
                              valor <= calificacionSeleccionada
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFE59819),
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      // Label Tu nombre
                      const Row(
                        children: [
                          Text(
                            'Tu nombre',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nombreController,
                        maxLength: 50,
                        onChanged: (_) {
                          if (nombreError != null) {
                            setSheetState(() => nombreError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'María Vargas',
                          counterText: '',
                          errorText: nombreError,
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: nombreError != null
                                  ? const Color(0xFFDC2626)
                                  : Colors.grey.shade300,
                              width: nombreError != null ? 1.5 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: nombreError != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF26674B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Label Comentario
                      Row(
                        children: [
                          const Text(
                            'Comentario',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Text(
                              'Opcional',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: comentarioController,
                        maxLines: 3,
                        maxLength: 500,
                        onChanged: (_) {
                          if (comentarioError != null) {
                            setSheetState(() => comentarioError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Cuéntanos tu experiencia...',
                          errorText: comentarioError,
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: comentarioError != null
                                  ? const Color(0xFFDC2626)
                                  : Colors.grey.shade300,
                              width: comentarioError != null ? 1.5 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: comentarioError != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF26674B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: enviando
                              ? null
                              : () async {
                                  if (!validarFormulario()) return;

                                  setSheetState(() => enviando = true);
                                  final nombre = nombreController.text.trim();
                                  final comentario = comentarioController.text
                                      .trim();

                                  final nuevaResena = Resena(
                                    entidad: widget.entidad,
                                    entidadId: widget.entidadId,
                                    autorNombre: nombre,
                                    calificacion: calificacionSeleccionada,
                                    comentario: comentario.isEmpty
                                        ? null
                                        : comentario,
                                    createdAt: DateTime.now(),
                                  );

                                  try {
                                    final repo = context
                                        .read<ResenaRepository>();
                                    await repo.create(nuevaResena);
                                    if (!mounted) return;
                                    setState(() {
                                      _resenas = [nuevaResena, ..._resenas];
                                    });
                                    _notificarResumen();
                                    if (sheetContext.mounted)
                                      Navigator.pop(sheetContext);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '¡Gracias por tu reseña!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    setSheetState(() => enviando = false);
                                    if (sheetContext.mounted) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo enviar la reseña: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26674B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: enviando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enviar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reseñas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143525),
                fontFamily: 'serif',
              ),
            ),
            TextButton.icon(
              onPressed: _abrirFormularioResena,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Escribir'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5A3F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_resenas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sé el primero en dejar una reseña',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          Column(children: _resenas.map(_buildResenaCard).toList()),
      ],
    );
  }

  Widget _buildResenaCard(Resena resena) {
    final iniciales = resena.autorNombre.trim().isNotEmpty
        ? resena.autorNombre.trim()[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE2ECE7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              iniciales,
              style: const TextStyle(
                color: Color(0xFF1B5A3F),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        resena.autorNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (resena.createdAt != null)
                      Text(
                        _fechaRelativa(resena.createdAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < resena.calificacion ? Icons.star : Icons.star_border,
                      size: 15,
                      color: const Color(0xFFE59819),
                    );
                  }),
                ),
                if (resena.comentario != null &&
                    resena.comentario!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    resena.comentario!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fechaRelativa(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inDays >= 30) {
      final meses = (diferencia.inDays / 30).floor();
      return meses <= 1 ? 'Hace 1 mes' : 'Hace $meses meses';
    }
    if (diferencia.inDays >= 1) {
      return diferencia.inDays == 1
          ? 'Hace 1 día'
          : 'Hace ${diferencia.inDays} días';
    }
    if (diferencia.inHours >= 1) {
      return diferencia.inHours == 1
          ? 'Hace 1 hora'
          : 'Hace ${diferencia.inHours} horas';
    }
    return 'Recién';
  }
}
