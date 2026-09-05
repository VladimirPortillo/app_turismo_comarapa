import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lugar.dart';

class LugarRepository {
  LugarRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre)';

  /// Bajo RLS: el público solo ve activos; administrador/editor ve todos.
  Future<List<Lugar>> fetchAll() async {
    final rows = await client
        .from('lugares')
        .select(_select)
        .order('created_at', ascending: false);

    return rows.map(Lugar.fromMap).toList();
  }

  Future<List<Lugar>> fetchActivos() async {
    final rows = await client
        .from('lugares')
        .select(_select)
        .eq('activo', true)
        .order('created_at', ascending: false);

    return rows.map(Lugar.fromMap).toList();
  }

  Future<void> create(Lugar lugar) async {
    await client.from('lugares').insert(lugar.toWriteMap());
  }

  Future<void> update(Lugar lugar) async {
    final id = lugar.id;
    if (id == null) {
      throw ArgumentError('El lugar no tiene id.');
    }
    await client.from('lugares').update(lugar.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('lugares').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
