import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/preferences_controller.dart';
import '../widgets/mode_banner.dart';
import 'about_adaptation_screen.dart';
import 'context/context_lab_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    final name =
        preferences.name.isEmpty ? 'Diplomante' : preferences.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyecto Final 360 - Sesion 2'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () {
              Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const ModeBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text(
                  'Hola, $name',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sesion 1: recordar. '
                  'Sesion 2: esperar, consultar, interpretar, '
                  'ubicarse y recuperarse de errores.',
                ),
                const SizedBox(height: 18),
                _MenuCard(
                  icon: Icons.storage_outlined,
                  title: '1. Mis registros',
                  subtitle: 'CRUD de la Sesion 1',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (routeContext) {
                          return const RecordsScreen();
                        },
                      ),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.public,
                  title: '2. Conexion con el mundo',
                  subtitle:
                      'Future + API + JSON + error + GPS + mapa',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (routeContext) {
                          return const ContextLabScreen();
                        },
                      ),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.tune,
                  title: '3. Preferencias',
                  subtitle: 'Persistencia local',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (routeContext) {
                          return const SettingsScreen();
                        },
                      ),
                    );
                  },
                ),
                _MenuCard(
                  icon: Icons.design_services_outlined,
                  title: '4. Adaptar a mi proyecto',
                  subtitle:
                      'API y hardware deben resolver tu problema',
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (routeContext) {
                          return const AboutAdaptationScreen();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
