// Pruebas de integración contra el proyecto real de Supabase, usando la
// clave publicable (el mismo acceso que tiene un visitante anónimo).
// Solo leen datos o intentan escrituras que la base de datos debe
// rechazar, así que no modifican nada.
//
// Ejecutar con: flutter test test/seguridad_rls_test.dart
@Tags(['integracion'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final config = jsonDecode(File('config/local.json').readAsStringSync())
      as Map<String, dynamic>;
  final url = config['SUPABASE_URL'].toString().trim();
  final key = config['SUPABASE_PUBLISHABLE_KEY'].toString().trim();
  final headers = <String, String>{
    'apikey': key,
    'Content-Type': 'application/json',
  };

  Future<http.Response> post(String path, Object body) => http.post(
        Uri.parse('$url$path'),
        headers: headers,
        body: jsonEncode(body),
      );

  test('un visitante puede leer los lugares activos', () async {
    final res = await http.get(
      Uri.parse('$url/rest/v1/lugares?select=id,nombre&limit=5'),
      headers: headers,
    );

    expect(res.statusCode, 200);
    expect(jsonDecode(res.body), isA<List<dynamic>>());
  });

  test('un visitante no puede crear lugares (RLS)', () async {
    final res = await post('/rest/v1/lugares', {'nombre': 'Prueba RLS'});

    expect(res.statusCode, anyOf(401, 403));
    expect(res.body, contains('row-level security'));
  });

  test('un visitante no puede ver la tabla de usuarios', () async {
    final res = await http.get(
      Uri.parse('$url/rest/v1/usuarios?select=id,correo,rol'),
      headers: headers,
    );

    // Sin permiso de lectura: error o lista vacía, nunca datos.
    if (res.statusCode == 200) {
      expect(jsonDecode(res.body), isEmpty);
    } else {
      expect(res.statusCode, anyOf(401, 403));
    }
  });

  test('una reseña con calificación fuera de 1..5 es rechazada', () async {
    final res = await post('/rest/v1/resenas', {
      'entidad': 'lugar',
      'entidad_id': '00000000-0000-0000-0000-000000000000',
      'autor_nombre': 'Prueba',
      'calificacion': 6,
      'estado_moderacion': 'aprobada',
    });

    expect(res.statusCode, greaterThanOrEqualTo(400));
  });

  test('una reseña que no viene como aprobada es rechazada', () async {
    final res = await post('/rest/v1/resenas', {
      'entidad': 'lugar',
      'entidad_id': '00000000-0000-0000-0000-000000000000',
      'autor_nombre': 'Prueba',
      'calificacion': 4,
      'estado_moderacion': 'pendiente',
    });

    expect(res.statusCode, anyOf(401, 403));
  });

  test('el login con contraseña incorrecta es rechazado', () async {
    final res = await post('/auth/v1/token?grant_type=password', {
      'email': 'no-existe-prueba@comarapa.test',
      'password': 'contrasena-incorrecta',
    });

    expect(res.statusCode, 400);
    expect(res.body, contains('invalid'));
    expect(res.body, isNot(contains('access_token')));
  });
}
