import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/context_controller.dart';
import 'controllers/preferences_controller.dart';
import 'repositories/registro_repository.dart';
import 'repositories/supabase_registro_repository.dart';
import 'services/location_service.dart';
import 'services/preferences_service.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();
  final prefs = await SharedPreferences.getInstance();

  final preferencesController = PreferencesController(
    PreferencesService(prefs),
  );

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );

  final RegistroRepository repository = SupabaseRegistroRepository(
    Supabase.instance.client,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        ChangeNotifierProvider<PreferencesController>.value(
          value: preferencesController,
        ),
        Provider<RegistroRepository>.value(value: repository),
        Provider<LocationService>(
          create: (providerContext) =>
              const LocationService(),
        ),
        Provider<WeatherService>(
          create: (providerContext) =>
              const WeatherService(),
        ),
        ChangeNotifierProvider<ContextController>(
          create: (providerContext) {
            return ContextController(
              locationService:
                  providerContext.read<LocationService>(),
              weatherService:
                  providerContext.read<WeatherService>(),
            );
          },
        ),
      ],
      child: const ProyectoFinalApp(),
    ),
  );
}
