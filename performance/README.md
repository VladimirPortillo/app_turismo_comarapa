# Pruebas de rendimiento

Todos los comandos se ejecutan desde la raíz del proyecto.

| Capa | Herramienta | Archivo | Requiere |
|------|-------------|---------|----------|
| Backend (Supabase) | k6 | `performance/k6/carga_supabase.js` | k6 + internet |
| Interfaz (FPS) | integration_test | `integration_test/rendimiento_test.dart` | celular Android + internet |
| Lógica (modelos) | flutter_test | `test/rendimiento_modelos_test.dart` | nada |
| Web publicada | Lighthouse | — | Chrome o Node |

## 1. Carga al backend (k6)

Instalar k6 una sola vez: `winget install k6 --source winget`

```bash
k6 run performance/k6/carga_supabase.js               # 10 usuarios simultáneos
k6 run -e USUARIOS=20 performance/k6/carga_supabase.js
```

Hace las mismas lecturas que la app (lugares, actividades, eventos, hoteles,
restaurantes) con la clave publicable. **No escribe datos.** El resumen se guarda
en `performance/resultados/k6_resumen.json`.

La prueba falla si más del 1 % de las peticiones dan error o si el p(95) supera 800 ms.
Con el plan gratuito de Supabase conviene no pasar de 20–30 usuarios.

## 2. Fluidez de la interfaz (FPS)

Con un celular Android conectado por USB (`flutter devices` debe mostrarlo):

```bash
flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/rendimiento_test.dart
```

La prueba abre la app, hace scroll en Inicio, Lugares y Eventos, y genera:
`build/scroll_inicio.timeline_summary.json`, `build/lugares.timeline_summary.json` y `build/eventos.timeline_summary.json`.

Valores a revisar en cada archivo:

- `average_frame_build_time_millis`: debe estar por debajo de 16 ms (60 FPS).
- `90th_percentile_frame_build_time_millis` y `worst_frame_build_time_millis`.
- `missed_frame_build_budget_count`: cuántos frames se trabaron.
- `average_frame_rasterizer_time_millis`: tiempo de dibujo en la GPU.

Para verlo de forma gráfica, ejecuta `flutter run --profile` y abre DevTools → **Performance**.

## 3. Micro-benchmark de modelos

```bash
flutter test test/rendimiento_modelos_test.dart
```

Mide la conversión de 10 000 filas a `Lugar` (referencia: unos 40 ms en una PC de escritorio).

## 4. Web publicada (Lighthouse)

```bash
flutter build web --release
npx lighthouse https://comarapa-turismo.web.app --view --output-path=performance/resultados/lighthouse.html
```

También se puede usar Chrome (F12 → Lighthouse) o https://pagespeed.web.dev.

## Tabla para el informe

| Métrica | Antes | Después |
|---------|-------|---------|
| Lighthouse Performance (web) | | |
| LCP (web) | | |
| k6 p(95) con 10 usuarios | | |
| k6 tasa de error | | |
| Frame promedio en Lugares (ms) | | |
| Frames perdidos en Lugares | | |
