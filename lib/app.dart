import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/preferences_controller.dart';
import 'screens/home_screen.dart';
import 'web/web_login_screen.dart';
import 'web/web_shell.dart';

/// Permite arrastrar con el mouse (además de touch/stylus) para que los
/// `PageView` y listas horizontales/verticales respondan al swipe en web/escritorio.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class ProyectoFinalApp extends StatelessWidget {
  const ProyectoFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comarapa Turismo',
      scrollBehavior: AppScrollBehavior(),
      themeMode: preferences.themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // En web se usa un diseño propio (lib/web); en móvil, las pantallas originales.
      home: kIsWeb ? const WebEntry() : const HomeScreen(),
      navigatorObservers: [if (kIsWeb) WebAuthRedirectObserver()],
    );
  }
}
