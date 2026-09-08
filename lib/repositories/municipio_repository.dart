import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/municipio.dart';

class MunicipioRepository {
  MunicipioRepository(this.client);

  final SupabaseClient client;

  /// El municipio es un registro único (id = 1). Si por algún motivo la
  /// fila no existe todavía, retorna un [Municipio] con los valores por
  /// defecto en vez de fallar.
  Future<Municipio> fetch() async {
    final row = await client.from('municipio').select().eq('id', 1).maybeSingle();
    if (row == null) return const Municipio();
    return Municipio.fromMap(row);
  }
}
