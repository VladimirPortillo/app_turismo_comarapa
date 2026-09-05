import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/actividad.dart';

class ActividadRepository {
  ActividadRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre)';

  Future<List<Actividad>> fetchAll() async {
    final rows = await client
        .from('actividades')
        .select(_select)
        .order('created_at', ascending: false);

    return rows.map(Actividad.fromMap).toList();
  }

  Future<List<Actividad>> fetchActivos() async {
    final rows = await client
        .from('actividades')
        .select(_select)
        .eq('activo', true)
        .order('created_at', ascending: false);

    return rows.map(Actividad.fromMap).toList();
  }

  Future<void> create(Actividad actividad) async {
    await client.from('actividades').insert(actividad.toWriteMap());
  }

  Future<void> update(Actividad actividad) async {
    final id = actividad.id;
    if (id == null) {
      throw ArgumentError('La actividad no tiene id.');
    }
    await client.from('actividades').update(actividad.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('actividades').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
