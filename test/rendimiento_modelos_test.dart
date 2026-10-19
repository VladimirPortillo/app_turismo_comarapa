// Micro-benchmark: mide cuánto tarda convertir las filas de Supabase
// en objetos Lugar, como pasa cada vez que se abre la pantalla de lugares.
// No usa internet.
//
// Ejecutar con: flutter test test/rendimiento_modelos_test.dart
@Tags(['rendimiento'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final_360/models/lugar.dart';

void main() {
  Map<String, dynamic> fila(int i) => <String, dynamic>{
        'id': i,
        'categoria_id': 3,
        'nombre': 'Lugar $i',
        'descripcion': 'Descripción de prueba del lugar número $i',
        'categorias': <String, dynamic>{'nombre': 'Naturaleza'},
        'imagenes': <dynamic>['a.jpg', 'b.jpg', 'c.jpg'],
        'latitud': -18.32,
        'longitud': -64.15,
        'direccion_referencia': 'Camino a Comarapa km $i',
        'dificultad': 'media',
        'tiempo_visita_min': 90,
        'costo_entrada': 15,
        'mejor_epoca': 'Invierno',
        'activo': true,
      };

  test('convierte 10 000 filas en Lugar en menos de 500 ms', () {
    final filas = List.generate(10000, fila);

    // Calentamiento: la primera pasada incluye la compilación JIT.
    filas.take(500).map(Lugar.fromMap).toList();

    final sw = Stopwatch()..start();
    final lugares = filas.map(Lugar.fromMap).toList();
    sw.stop();

    // ignore: avoid_print
    print('Lugar.fromMap x10000: ${sw.elapsedMilliseconds} ms '
        '(${(sw.elapsedMicroseconds / filas.length).toStringAsFixed(1)} µs por fila)');

    expect(lugares, hasLength(10000));
    expect(sw.elapsedMilliseconds, lessThan(500));
  });
}
