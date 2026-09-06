import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resultado de calcular una ruta entre dos puntos.
class RutaResultado {
  const RutaResultado({
    required this.puntos,
    required this.distanciaMetros,
    required this.duracionSegundos,
  });

  final List<LatLng> puntos;
  final double distanciaMetros;
  final double duracionSegundos;
}

/// Calcula rutas por carretera usando el servidor demo público de OSRM
/// (Open Source Routing Machine), sin necesidad de API key.
class RoutingService {
  const RoutingService();

  Future<RutaResultado> fetchRuta({
    required LatLng origen,
    required LatLng destino,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      throw const FormatException('No se encontró una ruta hacia ese lugar.');
    }

    final routes = decoded['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const FormatException('No se encontró una ruta hacia ese lugar.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    final puntos = coordinates.map((c) {
      final par = c as List;
      return LatLng((par[1] as num).toDouble(), (par[0] as num).toDouble());
    }).toList();

    return RutaResultado(
      puntos: puntos,
      distanciaMetros: (route['distance'] as num).toDouble(),
      duracionSegundos: (route['duration'] as num).toDouble(),
    );
  }
}
