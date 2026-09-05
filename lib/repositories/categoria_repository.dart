import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/categoria.dart';

class CategoriaRepository {
  CategoriaRepository(this.client);

  final SupabaseClient client;

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
    final row = await client
        .from('categorias')
        .insert(<String, dynamic>{
          'entidad': entidad,
          'nombre': nombre.trim(),
        })
        .select()
        .single();

    return Categoria.fromMap(row);
  }
}
