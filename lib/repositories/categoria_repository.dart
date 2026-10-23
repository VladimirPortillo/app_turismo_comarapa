import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/categoria.dart';

class CategoriaRepository {
  CategoriaRepository(this.client);

  final SupabaseClient client;

  /// Tabla que guarda el `categoria_id` de cada `entidad`.
  static const Map<String, String> _tablaPorEntidad = {
    'lugar': 'lugares',
    'actividad': 'actividades',
    'gastronomia': 'gastronomia',
    'hotel': 'hoteles',
    'restaurante': 'restaurantes',
    'evento': 'eventos',
  };

  Future<List<Categoria>> fetchByEntidad(String entidad) async {
    final rows = await client
        .from('categorias')
        .select()
        .eq('entidad', entidad)
        .eq('activo', true)
        .order('orden');

    return rows.map(Categoria.fromMap).toList();
  }

  Future<Categoria> create({
    required String entidad,
    required String nombre,
  }) async {
    final limpio = nombre.trim();
    try {
      final row = await client
          .from('categorias')
          .insert(<String, dynamic>{
            'entidad': entidad,
            'nombre': limpio,
          })
          .select()
          .single();

      return Categoria.fromMap(row);
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
      // Ya existe con ese nombre: si estaba eliminada (oculta), se reactiva.
      final rows = await client
          .from('categorias')
          .update(<String, dynamic>{'activo': true})
          .eq('entidad', entidad)
          .eq('nombre', limpio)
          .eq('activo', false)
          .select();
      if (rows.isEmpty) rethrow;
      return Categoria.fromMap(rows.first);
    }
  }

  /// Cambia el nombre de una categoría (para corregir errores de escritura).
  Future<Categoria> rename({required String id, required String nombre}) async {
    final row = await client
        .from('categorias')
        .update(<String, dynamic>{'nombre': nombre.trim()})
        .eq('id', id)
        .select()
        .single();

    return Categoria.fromMap(row);
  }

  /// "Elimina" la categoría ocultándola (`activo = false`). Los registros que
  /// ya la usaban la conservan; solo deja de aparecer para elegirla.
  Future<void> deactivate(String id) async {
    await client
        .from('categorias')
        .update(<String, dynamic>{'activo': false})
        .eq('id', id);
  }

  /// Cuántos registros del módulo usan la categoría (null si no se pudo contar).
  Future<int?> countUsos({required String entidad, required String id}) async {
    final tabla = _tablaPorEntidad[entidad];
    if (tabla == null) return null;
    try {
      return await client
          .from(tabla)
          .count(CountOption.exact)
          .eq('categoria_id', id);
    } catch (_) {
      return null;
    }
  }
}
