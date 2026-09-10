import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/gastronomia_item.dart';

class GastronomiaRepository {
  GastronomiaRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre), restaurantes(nombre)';

  Future<List<GastronomiaItem>> fetchAll() async {
    final rows = await client
        .from('gastronomia')
        .select(_select)
        .order('created_at', ascending: false);

    return rows.map(GastronomiaItem.fromMap).toList();
  }

  Future<List<GastronomiaItem>> fetchActivos() async {
    final rows = await client
        .from('gastronomia')
        .select(_select)
        .eq('activo', true)
        .order('created_at', ascending: false);

    return rows.map(GastronomiaItem.fromMap).toList();
  }

  /// Platos/bebidas típicos que se pueden encontrar en un restaurante
  /// específico (según el "dónde encontrarlo" asignado desde el panel).
  Future<List<GastronomiaItem>> fetchByRestaurante(String restauranteId) async {
    final rows = await client
        .from('gastronomia')
        .select(_select)
        .eq('restaurante_id', restauranteId)
        .eq('activo', true)
        .order('nombre', ascending: true);

    return rows.map(GastronomiaItem.fromMap).toList();
  }

  Future<void> create(GastronomiaItem item) async {
    await client.from('gastronomia').insert(item.toWriteMap());
  }

  Future<void> update(GastronomiaItem item) async {
    final id = item.id;
    if (id == null) {
      throw ArgumentError('El elemento de gastronomia no tiene id.');
    }
    await client.from('gastronomia').update(item.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('gastronomia').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
