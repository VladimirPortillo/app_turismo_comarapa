// Prueba de rendimiento de la interfaz (FPS / tiempo por frame).
// Abre la app real, entra a "Lugares" y "Eventos" y hace scroll, midiendo
// cuánto tarda cada frame. Usa Supabase real, así que requiere internet.
//
// Ejecutar en un celular Android conectado (modo profile = cifras reales):
//   flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/rendimiento_test.dart
//
// El resultado queda en build/<reportKey>.timeline_summary.json

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:proyecto_final_360/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder pestana(String nombre) => find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(nombre),
      );

  Future<void> hacerScroll(WidgetTester tester) async {
    final lista = find.byType(Scrollable).first;
    for (var i = 0; i < 3; i++) {
      await tester.fling(lista, const Offset(0, -600), 3000);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 3; i++) {
      await tester.fling(lista, const Offset(0, 600), 3000);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('rendimiento al navegar y hacer scroll', (tester) async {
    app.main();
    // Espera a que carguen Supabase y la pantalla de inicio.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await binding.traceAction(() async {
      await hacerScroll(tester);
    }, reportKey: 'scroll_inicio');

    await binding.traceAction(() async {
      await tester.tap(pestana('Lugares'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await hacerScroll(tester);
    }, reportKey: 'lugares');

    await binding.traceAction(() async {
      await tester.tap(pestana('Eventos'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await hacerScroll(tester);
    }, reportKey: 'eventos');
  });
}
