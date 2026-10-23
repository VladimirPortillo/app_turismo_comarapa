import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/categoria.dart';
import '../repositories/categoria_repository.dart';

const _kPrimary = Color(0xFF26674B);
const _kTitulo = Color(0xFF0C3D28);
const _kPeligro = Color(0xFFDC2626);

/// Resultado de [mostrarAccionesCategoria]: la categoría se renombró
/// (`editada`) o se eliminó (`eliminada`).
class CategoriaAccionResultado {
  const CategoriaAccionResultado.editada(Categoria this.editada) : eliminada = false;
  const CategoriaAccionResultado.eliminada() : editada = null, eliminada = true;

  final Categoria? editada;
  final bool eliminada;
}

/// Devuelve la lista con la categoría reemplazada (editada) o quitada (eliminada).
List<Categoria> aplicarResultadoCategoria(
  List<Categoria> lista,
  Categoria original,
  CategoriaAccionResultado resultado,
) {
  if (resultado.eliminada) {
    return lista.where((c) => c.id != original.id).toList();
  }
  return lista.map((c) => c.id == original.id ? resultado.editada! : c).toList();
}

/// Menú que se abre al mantener presionada (o clic derecho en web) una
/// categoría, con las opciones "Editar nombre" y "Eliminar".
Future<CategoriaAccionResultado?> mostrarAccionesCategoria(
  BuildContext context,
  Categoria categoria,
) async {
  final accion = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categoria.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTitulo),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: _kPrimary),
            title: const Text('Editar nombre'),
            onTap: () => Navigator.pop(ctx, 'editar'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: _kPeligro),
            title: const Text('Eliminar', style: TextStyle(color: _kPeligro)),
            onTap: () => Navigator.pop(ctx, 'eliminar'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (!context.mounted || accion == null) return null;
  if (accion == 'editar') return _editar(context, categoria);
  return _eliminar(context, categoria);
}

Future<CategoriaAccionResultado?> _editar(BuildContext context, Categoria categoria) async {
  final controller = TextEditingController(text: categoria.nombre);
  final nuevoNombre = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Editar categoría',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _kTitulo),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  final nombre = nuevoNombre?.trim() ?? '';
  if (!context.mounted || nombre.isEmpty || nombre == categoria.nombre) return null;
  if (nombre.length < 2) {
    _aviso(context, 'El nombre debe tener al menos 2 caracteres.');
    return null;
  }

  try {
    final editada = await context.read<CategoriaRepository>().rename(
          id: categoria.id,
          nombre: nombre,
        );
    if (context.mounted) _aviso(context, 'Categoría actualizada.', exito: true);
    return CategoriaAccionResultado.editada(editada);
  } on PostgrestException catch (e) {
    if (context.mounted) {
      _aviso(
        context,
        e.code == '23505'
            ? 'Ya existe una categoría con ese nombre.'
            : 'No se pudo editar la categoría: ${e.message}',
      );
    }
  } catch (e) {
    if (context.mounted) _aviso(context, 'No se pudo editar la categoría: $e');
  }
  return null;
}

Future<CategoriaAccionResultado?> _eliminar(BuildContext context, Categoria categoria) async {
  final repo = context.read<CategoriaRepository>();
  final usos = await repo.countUsos(entidad: categoria.entidad, id: categoria.id);
  if (!context.mounted) return null;

  final String detalle;
  if (usos == null || usos == 0) {
    detalle = 'Ya no aparecerá en la lista para elegirla.';
  } else {
    final quienes = usos == 1 ? '1 registro la usa' : '$usos registros la usan';
    detalle = '$quienes y la conservarán, pero ya no podrás elegirla '
        'para nuevos registros.';
  }

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '¿Eliminar "${categoria.nombre}"?',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _kTitulo),
      ),
      content: Text(detalle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _kPeligro,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (!context.mounted || confirmar != true) return null;

  try {
    await repo.deactivate(categoria.id);
    if (context.mounted) _aviso(context, 'Categoría eliminada.', exito: true);
    return const CategoriaAccionResultado.eliminada();
  } catch (e) {
    if (context.mounted) _aviso(context, 'No se pudo eliminar la categoría: $e');
    return null;
  }
}

void _aviso(BuildContext context, String mensaje, {bool exito = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor: exito ? _kPrimary : _kPeligro,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
