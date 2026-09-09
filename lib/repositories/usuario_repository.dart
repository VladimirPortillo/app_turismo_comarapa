import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_perfil.dart';

class UsuarioRepository {
  UsuarioRepository(this.client);

  final SupabaseClient client;

  Future<UsuarioPerfil?> fetchCurrent() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    return UsuarioPerfil.fromMap(row);
  }

  Future<List<UsuarioPerfil>> fetchAll() async {
    final rows = await client
        .from('usuarios')
        .select()
        .order('created_at', ascending: false);

    return (rows as List).map((row) => UsuarioPerfil.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> updateRol(String id, String nuevoRol) async {
    await client.from('usuarios').update({'rol': nuevoRol}).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('usuarios').update({'activo': activo}).eq('id', id);
  }

  Future<void> updatePerfil({
    required String id,
    required String nombre,
    required String rol,
    required bool activo,
  }) async {
    await client.from('usuarios').update({
      'nombre': nombre.trim(),
      'rol': rol,
      'activo': activo,
    }).eq('id', id);
  }
}
