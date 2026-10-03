import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/weather_snapshot.dart';
import '../services/weather_service.dart';
import 'web_theme.dart';

/// Clima actual de Comarapa (Open-Meteo, igual que la app), en una tarjeta
/// del mismo alto que el buscador de la portada. Se actualiza solo cada
/// [intervalo] y con el botón de recargar.
class WebClimaChip extends StatefulWidget {
  const WebClimaChip({
    super.key,
    required this.punto,
    this.intervalo = const Duration(minutes: 10),
  });

  final LatLng punto;
  final Duration intervalo;

  @override
  State<WebClimaChip> createState() => _WebClimaChipState();
}

class _WebClimaChipState extends State<WebClimaChip> {
  WeatherSnapshot? _clima;
  bool _cargando = true;
  bool _error = false;
  DateTime? _actualizado;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(widget.intervalo, (_) => _cargar());
  }

  @override
  void didUpdateWidget(WebClimaChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Llegaron las coordenadas reales del municipio: se vuelve a consultar.
    if (oldWidget.punto != widget.punto) _cargar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final clima = await context.read<WeatherService>().fetchCurrent(
            latitude: widget.punto.latitude,
            longitude: widget.punto.longitude,
          );
      if (!mounted) return;
      setState(() {
        _clima = clima;
        _error = false;
        _cargando = false;
        _actualizado = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Si ya había un dato, se sigue mostrando el último.
        _error = _clima == null;
        _cargando = false;
      });
    }
  }

  String get _horaActualizado {
    final t = _actualizado;
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return 'Actualizado $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final clima = _clima;

    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (clima != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorFondoClima(clima.weatherCode),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconoClima(clima.weatherCode),
                color: colorIconoClima(clima.weatherCode),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${clima.temperatureC.toStringAsFixed(1)} °C  ·  ${clima.summary}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: WebTheme.verdeOscuro,
                  ),
                ),
                Text(
                  'Comarapa · ${_sensacion(clima.temperatureC)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ] else if (_error)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    'Clima no disponible',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Consultando clima...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: _actualizado == null
                ? 'Actualizar clima'
                : '$_horaActualizado · Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: _cargando && clima != null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, size: 20, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Mismo criterio que la app: Cálido / Agradable / Fresco.
  static String _sensacion(double t) {
    if (t >= 25) return 'Cálido';
    if (t >= 18) return 'Agradable';
    return 'Fresco';
  }
}

// Íconos y colores por código de Open-Meteo (mismos que la app).

const _lluvia = <int>[51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82];
const _nieve = <int>[71, 73, 75, 77, 85, 86];
const _tormenta = <int>[95, 96, 99];

IconData iconoClima(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code == 1 || code == 2) return Icons.wb_cloudy_rounded;
  if (code == 3) return Icons.cloud_rounded;
  if (code == 45 || code == 48) return Icons.foggy;
  if (_lluvia.contains(code)) return Icons.water_drop_rounded;
  if (_nieve.contains(code)) return Icons.ac_unit_rounded;
  if (_tormenta.contains(code)) return Icons.thunderstorm_rounded;
  return Icons.wb_sunny_rounded;
}

Color colorIconoClima(int code) {
  if (code == 0) return const Color(0xFFF59E0B);
  if (code == 1 || code == 2) return const Color(0xFF0284C7);
  if (code == 3) return const Color(0xFF64748B);
  if (code == 45 || code == 48) return const Color(0xFF94A3B8);
  if (_lluvia.contains(code)) return const Color(0xFF2563EB);
  if (_nieve.contains(code)) return const Color(0xFF38BDF8);
  if (_tormenta.contains(code)) return const Color(0xFF7C3AED);
  return const Color(0xFFF59E0B);
}

Color colorFondoClima(int code) {
  if (code == 0) return const Color(0xFFFEF3C7);
  if (code == 1 || code == 2) return const Color(0xFFE0F2FE);
  if (code == 3 || code == 45 || code == 48) return const Color(0xFFF1F5F9);
  if (_lluvia.contains(code)) return const Color(0xFFDBEAFE);
  if (_nieve.contains(code)) return const Color(0xFFE0F2FE);
  if (_tormenta.contains(code)) return const Color(0xFFEDE9FE);
  return const Color(0xFFFEF3C7);
}
