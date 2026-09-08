import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/resena.dart';

class ResenaRepository {
  ResenaRepository(this.client);

  final SupabaseClient client;

  Future<List<Resena>> fetchAprobadas({
    required String entidad,
    required String entidadId,
  }) async {
    final rows = await client
        .from('resenas')
        .select()
        .eq('entidad', entidad)
        .eq('entidad_id', entidadId)
        .eq('estado_moderacion', 'aprobada')
        .order('created_at', ascending: false);

    return rows.map(Resena.fromMap).toList();
  }

  Future<void> create(Resena resena) async {
    await client.from('resenas').insert(resena.toWriteMap());
  }
}
