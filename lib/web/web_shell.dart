import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/actividad.dart';
import '../models/evento.dart';
import '../models/gastronomia_item.dart';
import '../models/hotel.dart';
import '../models/lugar.dart';
import '../models/restaurante.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import 'web_activities_screen.dart';
import 'web_activity_detail_screen.dart';
import 'web_event_detail_screen.dart';
import 'web_events_screen.dart';
import 'web_gastronomy_detail_screen.dart';
import 'web_gastronomy_screen.dart';
import 'web_home_screen.dart';
import 'web_hotel_detail_screen.dart';
import 'web_hotels_screen.dart';
import 'web_login_screen.dart';
import 'web_place_detail_screen.dart';
import 'web_places_screen.dart';
import 'web_restaurant_detail_screen.dart';
import 'web_restaurants_screen.dart';
import 'web_search.dart';
import 'web_theme.dart';

/// Punto de entrada web: en pantallas anchas usa el layout de escritorio
/// y en pantallas angostas (celular en navegador) usa el diseño móvil original.
class WebEntry extends StatelessWidget {
  const WebEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho < WebTheme.breakpoint) {
      return const HomeScreen();
    }
    return const WebShell();
  }
}

/// Pantalla de detalle web para un elemento del mapa.
Widget detalleWeb(Object item) {
  return switch (item) {
    Lugar() => WebPlaceDetailScreen(lugar: item),
    Actividad() => WebActivityDetailScreen(actividad: item),
    Hotel() => WebHotelDetailScreen(hotel: item),
    Restaurante() => WebRestaurantDetailScreen(restaurante: item),
    Evento() => WebEventDetailScreen(evento: item),
    GastronomiaItem() => WebGastronomyDetailScreen(item: item),
    _ => throw ArgumentError('Tipo no soportado en el mapa: $item'),
  };
}

class _Seccion {
  const _Seccion(this.label, this.icon);
  final String label;
  final IconData icon;
}

const List<_Seccion> _secciones = [
  _Seccion('Inicio', Icons.home_rounded),
  _Seccion('Lugares', Icons.location_on_outlined),
  _Seccion('Actividades', Icons.calendar_month_outlined),
  _Seccion('Gastronomía', Icons.restaurant),
  _Seccion('Hoteles', Icons.hotel_outlined),
  _Seccion('Restaurantes', Icons.local_cafe_outlined),
  _Seccion('Eventos', Icons.event_outlined),
  _Seccion('Mapa', Icons.map_outlined),
];

/// Layout de escritorio: barra de navegación superior + contenido centrado.
class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _index = 0;

  void _irA(int index) => setState(() => _index = index);

  void _volverInicio() => _irA(0);

  Widget _buildContenido() {
    switch (_index) {
      case 0:
        return WebHomeScreen(onNavigate: _irA);
      case 1:
        return const WebPlacesScreen();
      case 2:
        return const WebActivitiesScreen();
      case 3:
        return const WebGastronomyScreen();
      case 4:
        return const WebHotelsScreen();
      case 5:
        return const WebRestaurantsScreen();
      case 6:
        return const WebEventsScreen();
      case 7:
        return const MapScreen(detalleBuilder: detalleWeb);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ctrl + K abre el buscador global desde cualquier sección.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showWebSearch(context),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            showWebSearch(context),
      },
      child: Focus(autofocus: true, child: _buildScaffold()),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildNavbar(),
          const Divider(height: 1),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF3F4F1),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _buildContenido(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      color: Colors.white,
      height: 72,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              InkWell(
                onTap: _volverInicio,
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(28, 24),
                      painter: GreenMountainLogoPainter(),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Comarapa',
                      style: TextStyle(
                        color: WebTheme.verdeOscuro,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final modo = _modoMenu(constraints.maxWidth);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _secciones.length; i++)
                          _buildNavItem(i, modo),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: WebTheme.verdeOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WebAuthGate()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tamaños del menú, de más amplio a más compacto.
  static const _modos = [
    (padding: 14.0, margen: 3.0, etiqueta: true),
    (padding: 8.0, margen: 1.0, etiqueta: true),
    (padding: 10.0, margen: 2.0, etiqueta: false),
  ];

  static const double _anchoIcono = 20;
  static const double _espacioIconoTexto = 8;
  static const TextStyle _estiloMenu = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  /// Elige el tamaño más amplio en el que caben todas las opciones.
  ({double padding, double margen, bool etiqueta}) _modoMenu(double ancho) {
    final textos = [
      for (final s in _secciones)
        (TextPainter(
          text: TextSpan(text: s.label, style: _estiloMenu),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout()).width,
    ];
    for (final modo in _modos) {
      var necesario = 0.0;
      for (final t in textos) {
        necesario += modo.padding * 2 + modo.margen * 2 + _anchoIcono;
        if (modo.etiqueta) necesario += _espacioIconoTexto + t;
      }
      if (necesario <= ancho) return modo;
    }
    return _modos.last;
  }

  Widget _buildNavItem(
    int i,
    ({double padding, double margen, bool etiqueta}) modo,
  ) {
    final seleccionado = i == _index;
    final seccion = _secciones[i];
    final estilo = TextButton.styleFrom(
      foregroundColor: seleccionado ? WebTheme.verde : WebTheme.texto,
      backgroundColor: seleccionado ? WebTheme.verdeClaro : null,
      padding: EdgeInsets.symmetric(horizontal: modo.padding, vertical: 12),
      minimumSize: Size.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: modo.margen),
      child: modo.etiqueta
          ? TextButton.icon(
              onPressed: () => _irA(i),
              style: estilo,
              icon: Icon(seccion.icon, size: _anchoIcono),
              label: Text(
                seccion.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            )
          // Ventana angosta: solo íconos, con el nombre al pasar el mouse.
          : Tooltip(
              message: seccion.label,
              child: TextButton(
                onPressed: () => _irA(i),
                style: estilo,
                child: Icon(seccion.icon, size: _anchoIcono),
              ),
            ),
    );
  }
}
