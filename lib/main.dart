import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/context_controller.dart';
import 'controllers/preferences_controller.dart';
import 'repositories/actividad_repository.dart';
import 'repositories/categoria_repository.dart';
import 'repositories/evento_repository.dart';
import 'repositories/gastronomia_repository.dart';
import 'repositories/hotel_repository.dart';
import 'repositories/lugar_repository.dart';
import 'repositories/registro_repository.dart';
import 'repositories/restaurante_repository.dart';
import 'repositories/supabase_registro_repository.dart';
import 'repositories/usuario_repository.dart';
import 'services/image_upload_service.dart';
import 'services/location_service.dart';
import 'services/preferences_service.dart';
import 'services/routing_service.dart';
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

  final supabaseClient = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        ChangeNotifierProvider<PreferencesController>.value(
          value: preferencesController,
        ),
        Provider<RegistroRepository>.value(value: repository),
        Provider<CategoriaRepository>(
          create: (_) => CategoriaRepository(supabaseClient),
        ),
        Provider<LugarRepository>(
          create: (_) => LugarRepository(supabaseClient),
        ),
        Provider<ActividadRepository>(
          create: (_) => ActividadRepository(supabaseClient),
        ),
        Provider<HotelRepository>(
          create: (_) => HotelRepository(supabaseClient),
        ),
        Provider<EventoRepository>(
          create: (_) => EventoRepository(supabaseClient),
        ),
        Provider<GastronomiaRepository>(
          create: (_) => GastronomiaRepository(supabaseClient),
        ),
        Provider<RestauranteRepository>(
          create: (_) => RestauranteRepository(supabaseClient),
        ),
        Provider<UsuarioRepository>(
          create: (_) => UsuarioRepository(supabaseClient),
        ),
        Provider<ImageUploadService>(
          create: (_) => ImageUploadService(supabaseClient),
        ),
        Provider<LocationService>(
          create: (providerContext) =>
              const LocationService(),
        ),
        Provider<WeatherService>(
          create: (providerContext) =>
              const WeatherService(),
        ),
        Provider<RoutingService>(
          create: (providerContext) =>
              const RoutingService(),
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
