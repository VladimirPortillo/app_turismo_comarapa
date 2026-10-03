import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../models/lugar.dart';
import '../models/municipio.dart';
import '../repositories/evento_repository.dart';
import '../repositories/lugar_repository.dart';
import '../repositories/municipio_repository.dart';
import '../screens/home_screen.dart';
import 'web_clima.dart';
import 'web_event_detail_screen.dart';
import 'web_places_screen.dart';
import 'web_search.dart';
import 'web_theme.dart';
import 'web_widgets.dart' show showWebMapDialog;

/// Página de inicio exclusiva para la versión web de escritorio.
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key, required this.onNavigate});

  /// Cambia de sección en el [WebShell] (mismo índice que la barra superior).
  final ValueChanged<int> onNavigate;

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  List<Lugar> _lugares = <Lugar>[];
  bool _loadingLugares = true;

  List<Evento> _eventos = <Evento>[];
  bool _loadingEventos = true;

  Municipio? _municipio;

  // Plaza principal de Comarapa, si el municipio aún no tiene ubicación
  // en Supabase (mismo valor que la app).
  static const LatLng _puntoPorDefecto = LatLng(-17.9144, -64.5319);

  @override
  void initState() {
    super.initState();
    _loadLugares();
    _loadEventos();
    _loadMunicipio();
  }

  Future<void> _loadMunicipio() async {
    try {
      final municipio = await context.read<MunicipioRepository>().fetch();
      if (mounted) setState(() => _municipio = municipio);
    } catch (_) {
      // Sin datos del municipio se usa la ubicación por defecto.
    }
  }

  LatLng get _puntoMunicipio {
    final lat = _municipio?.latitud;
    final lng = _municipio?.longitud;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return _puntoPorDefecto;
  }

  /// Abre el mapa completo (con "Mi ubicación" y "Cómo llegar").
  void _ampliarMapa() {
    showWebMapDialog(
      context,
      titulo: _municipio?.nombre ?? 'Comarapa',
      subtitulo: 'Municipio de Comarapa · Santa Cruz, Bolivia',
      destino: _puntoMunicipio,
    );
  }

  Future<void> _loadLugares() async {
    try {
      final lugares = await context.read<LugarRepository>().fetchActivos();
      if (!mounted) return;
      setState(() {
        _lugares = lugares.take(8).toList();
        _loadingLugares = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLugares = false);
    }
  }

  Future<void> _loadEventos() async {
    try {
      final eventos = await context.read<EventoRepository>().fetchActivos();
      if (!mounted) return;
      final hoy = DateTime.now();
      final proximos = eventos
          .where((e) => !(e.fechaFin ?? e.fechaInicio).isBefore(hoy))
          .toList()
        ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
      setState(() {
        _eventos = (proximos.isNotEmpty ? proximos : eventos).take(3).toList();
        _loadingEventos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingEventos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(),
          const SizedBox(height: 48),
          WebContainer(child: _buildCategorias()),
          const SizedBox(height: 56),
          WebContainer(child: _buildDestacados()),
          const SizedBox(height: 56),
          WebContainer(child: _buildEventos()),
          const SizedBox(height: 56),
          WebContainer(child: _buildUbicacion()),
          const SizedBox(height: 64),
          _buildFooter(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Hero

  Widget _buildHero() {
    return SizedBox(
      height: 440,
      child: CustomPaint(
        painter: BannerBackgroundPainter(),
        child: WebContainer(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EL PARAÍSO ESCONDIDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Descubre Comarapa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                        fontFamily: 'serif',
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Valles, montañas y la puerta al Parque Nacional Amboró. '
                      'Planifica tu visita: lugares, hoteles, gastronomía y eventos '
                      'en un solo sitio.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: _buildBuscadorHero()),
                        const SizedBox(width: 12),
                        WebClimaChip(punto: _puntoMunicipio),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => widget.onNavigate(1),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: WebTheme.verdeOscuro,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text(
                            'Explorar lugares',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => widget.onNavigate(7),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Ver mapa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuscadorHero() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showWebSearch(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: WebTheme.verde),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Qué quieres descubrir? Lugares, hoteles, eventos...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Categorías

  Widget _buildCategorias() {
    const categorias = [
      (1, 'Lugares', Icons.location_on_outlined, false),
      (2, 'Actividades', Icons.explore_outlined, false),
      (3, 'Gastronomía', Icons.restaurant_menu_outlined, true),
      (4, 'Hoteles', Icons.hotel_outlined, false),
      (5, 'Restaurantes', Icons.storefront_outlined, true),
      (6, 'Eventos', Icons.calendar_today_outlined, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Explora por categoría'),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final (index, label, icon, calido) in categorias)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _CategoriaCard(
                    label: label,
                    icon: icon,
                    fondo: calido
                        ? const Color(0xFFF9EFE5)
                        : WebTheme.verdeClaro,
                    color: calido ? WebTheme.durazno : WebTheme.verde,
                    onTap: () => widget.onNavigate(index),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------- Destacados

  Widget _buildDestacados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _titulo('Lugares destacados')),
            TextButton(
              onPressed: () => widget.onNavigate(1),
              child: const Text('Ver todos →'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_loadingLugares)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_lugares.isEmpty)
          const Text('Todavía no hay lugares publicados.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth > 1000 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lugares.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, i) => WebLugarCard(lugar: _lugares[i]),
              );
            },
          ),
      ],
    );
  }

  // ------------------------------------------------------------- Eventos

  Widget _buildEventos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _titulo('Próximos eventos')),
            TextButton(
              onPressed: () => widget.onNavigate(6),
              child: const Text('Ver calendario →'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_loadingEventos)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_eventos.isEmpty)
          const Text('No hay eventos programados.')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 20),
                    child: i < _eventos.length
                        ? _EventoCard(evento: _eventos[i])
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // -------------------------------------------------------------- Footer

  // ----------------------------------------------------------- Ubicación

  Widget _buildUbicacion() {
    final m = _municipio;
    final descripcion = m?.descripcion.trim() ?? '';
    final datos = <({IconData icono, String titulo, String valor})>[
      if (m?.altitudMsnm != null)
        (
          icono: Icons.terrain_outlined,
          titulo: 'Altitud',
          valor: '${m!.altitudMsnm} m s. n. m.',
        ),
      if (m?.poblacion != null)
        (
          icono: Icons.groups_outlined,
          titulo: 'Población',
          valor: '${m!.poblacion} hab.',
        ),
      if (m?.clima?.trim().isNotEmpty ?? false)
        (icono: Icons.wb_sunny_outlined, titulo: 'Clima', valor: m!.clima!.trim()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Cómo llegar a Comarapa'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa con marcador y botón para ampliar.
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 380,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _puntoMunicipio,
                          initialZoom: 13,
                          // Sin zoom con la rueda para no trabar el scroll.
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.drag |
                                InteractiveFlag.pinchZoom |
                                InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'bo.edu.uajms.proyecto_final_360',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _puntoMunicipio,
                                width: 48,
                                height: 48,
                                child: const Icon(
                                  Icons.location_on,
                                  size: 44,
                                  color: Color(0xFF26674B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FilledButton.icon(
                          onPressed: _ampliarMapa,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: WebTheme.verdeOscuro,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.fullscreen),
                          label: const Text(
                            'Ampliar mapa',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Información del municipio y botón "Cómo llegar".
            Expanded(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(minHeight: 380),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: WebTheme.verdeClaro,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.place, color: WebTheme.verde),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m?.nombre ?? 'Comarapa',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: WebTheme.verdeOscuro,
                                  fontFamily: 'serif',
                                ),
                              ),
                              Text(
                                'Santa Cruz, Bolivia',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (descripcion.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        descripcion,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WebTheme.texto,
                          height: 1.55,
                        ),
                      ),
                    ],
                    if (datos.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final d in datos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(d.icono, size: 20, color: WebTheme.verde),
                              const SizedBox(width: 10),
                              Text(
                                d.titulo,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const Spacer(),
                              Text(
                                d.valor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Abre el mapa y pulsa "Cómo llegar" para ver la ruta '
                      'desde tu ubicación actual.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _ampliarMapa,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF26674B),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text(
                        'Cómo llegar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: WebTheme.verdeOscuro,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: WebContainer(
        child: Row(
          children: [
            CustomPaint(
              size: const Size(28, 24),
              painter: GreenMountainLogoPainter(),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Municipio de Comarapa · Santa Cruz, Bolivia',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            Text(
              '© ${DateTime.now().year} Comarapa Turismo',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: WebTheme.verdeOscuro,
        fontFamily: 'serif',
      ),
    );
  }
}

// =================================================================== Cards

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({
    required this.label,
    required this.icon,
    required this.fondo,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fondo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WebHoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: WebTheme.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    return WebHoverCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WebEventDetailScreen(evento: evento)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: evento.badgeBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    evento.diaFormateado,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: evento.badgeTextColor,
                    ),
                  ),
                  Text(
                    evento.mesAbreviado,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: evento.badgeTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.verdeOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    evento.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
