import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/restaurante.dart';

class RestauranteRepository {
  RestauranteRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre)';

  Future<List<Restaurante>> fetchAll() async {
    final rows = await client
        .from('restaurantes')
        .select(_select)
        .order('created_at', ascending: false);

    return rows.map(Restaurante.fromMap).toList();
  }

  Future<List<Restaurante>> fetchActivos() async {
    final rows = await client
        .from('restaurantes')
        .select(_select)
        .eq('activo', true)
        .order('nombre', ascending: true);

    return rows.map(Restaurante.fromMap).toList();
  }

  Future<Restaurante?> fetchById(String id) async {
    final row = await client
        .from('restaurantes')
        .select(_select)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return Restaurante.fromMap(row);
  }

  Future<void> create(Restaurante restaurante) async {
    await client.from('restaurantes').insert(restaurante.toWriteMap());
  }

  Future<void> update(Restaurante restaurante) async {
    final id = restaurante.id;
    if (id == null) {
      throw ArgumentError('El restaurante no tiene id.');
    }
    await client.from('restaurantes').update(restaurante.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('restaurantes').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
