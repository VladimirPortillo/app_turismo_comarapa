import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hotel.dart';

class HotelRepository {
  HotelRepository(this.client);

  final SupabaseClient client;

  static const String _select = '*, categorias(nombre)';

  Future<List<Hotel>> fetchAll() async {
    final rows = await client
        .from('hoteles')
        .select(_select)
        .order('created_at', ascending: false);

    return rows.map(Hotel.fromMap).toList();
  }

  Future<List<Hotel>> fetchActivos() async {
    final rows = await client
        .from('hoteles')
        .select(_select)
        .eq('activo', true)
        .order('created_at', ascending: false);

    return rows.map(Hotel.fromMap).toList();
  }

  Future<void> create(Hotel hotel) async {
    await client.from('hoteles').insert(hotel.toWriteMap());
  }

  Future<void> update(Hotel hotel) async {
    final id = hotel.id;
    if (id == null) {
      throw ArgumentError('El hotel no tiene id.');
    }
    await client.from('hoteles').update(hotel.toWriteMap()).eq('id', id);
  }

  Future<void> setActivo(String id, bool activo) async {
    await client.from('hoteles').update(<String, dynamic>{'activo': activo}).eq('id', id);
  }
}
