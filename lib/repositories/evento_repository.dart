import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evento.dart';

class EventoRepository {
  EventoRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre)';

  Future<List<Evento>> fetchAll() async {
    final rows = await client
        .from('eventos')
        .select(_select)
        .order('fecha_inicio', ascending: true);

    return rows.map(Evento.fromMap).toList();
  }

  Future<List<Evento>> fetchActivos() async {
    final rows = await client
        .from('eventos')
        .select(_select)
        .eq('activo', true)
        .order('fecha_inicio', ascending: true);

    return rows.map(Evento.fromMap).toList();
  }

  Future<void> create(Evento evento) async {
    await client.from('eventos').insert(evento.toWriteMap());
  }

  Future<void> update(Evento evento) async {
    final id = evento.id;
    if (id == null) {
      throw ArgumentError('El evento no tiene id.');
    }
    await client.from('eventos').update(evento.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('eventos').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
