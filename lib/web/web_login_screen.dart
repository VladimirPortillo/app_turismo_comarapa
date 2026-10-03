import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/admin_home_screen.dart';
import '../screens/auth_gate.dart';
import '../screens/home_screen.dart' show BannerBackgroundPainter;
import '../screens/login_screen.dart' show MountainLogoPainter;
import '../services/auth_service.dart';
import 'web_admin_screen.dart';
import 'web_theme.dart';

/// Versión web de [AuthGate]: muestra el login web si no hay sesión
/// y el panel de administración si ya se inició sesión.
class WebAuthGate extends StatelessWidget {
  const WebAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (client.auth.currentSession == null) {
          return const WebLoginScreen();
        }
        return const WebAdminScreen();
      },
    );
  }
}

/// Observador de navegación (solo web): cuando alguna pantalla de la app
/// abre el [AuthGate] o el [AdminHomeScreen] móviles —por ejemplo, la
/// gestión de usuarios al cerrar sesión o al volver al panel— los reemplaza
/// por sus versiones web, sin modificar esas pantallas.
class WebAuthRedirectObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _redirigir(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _redirigir(newRoute);
  }

  void _redirigir(Route<dynamic> route) {
    final navigator = route.navigator;
    if (route is! MaterialPageRoute || navigator == null) return;

    final pantalla = route.builder(navigator.context);
    final Widget? reemplazo = switch (pantalla) {
      AuthGate() => const WebAuthGate(),
      AdminHomeScreen(:final initialTipo) =>
        WebAdminScreen(initialTipo: initialTipo),
      _ => null,
    };
    if (reemplazo == null) return;

    // El Navigator está bloqueado durante el push: se reemplaza justo después.
    // Se usa pushReplacement (y no replace) porque replace copia el progreso
    // de la animación de la ruta original —que en este instante es 0— y la
    // nueva pantalla quedaba invisible bloqueando los toques ("se colgaba").
    scheduleMicrotask(() {
      if (!route.isCurrent) return;
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => reemplazo),
      );
    });
  }
}

/// Inicio de sesión para la versión web: panel de marca a la izquierda
/// y formulario a la derecha (solo el formulario en ventanas angostas).
class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  static const Color _verdeBoton = Color(0xFF2E7D52);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_limpiarError);
    _passwordController.addListener(_limpiarError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _limpiarError() {
    if (_error != null) setState(() => _error = null);
  }

  /// Mismos mensajes en español que la pantalla de login de la app.
  String _traducirErrorAuth(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_grant') ||
          msg.contains('invalid credentials')) {
        return 'Correo o contraseña incorrectos. Por favor, verifica tus datos.';
      }
      if (msg.contains('email not confirmed')) {
        return 'El correo electrónico no ha sido confirmado. Revisa tu bandeja de entrada.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Demasiados intentos. Por favor espera unos momentos antes de reintentar.';
      }
      if (msg.contains('user not found')) {
        return 'Usuario no encontrado. Verifica el correo ingresado.';
      }
      if (msg.contains('invalid email')) {
        return 'El formato de correo electrónico es inválido.';
      }
      return 'Error de autenticación: ${error.message}';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('clientexception') ||
        errStr.contains('failed host lookup')) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión a internet.';
    }
    if (errStr.contains('timeout')) {
      return 'El servidor tardó demasiado en responder. Inténtalo nuevamente.';
    }
    return 'Ocurrió un error inesperado al iniciar sesión. Inténtalo de nuevo.';
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthService(Supabase.instance.client).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Al iniciar sesión, [WebAuthGate] muestra el panel de administración.
    } catch (error) {
      if (mounted) setState(() => _error = _traducirErrorAuth(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= WebTheme.breakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ancho) Expanded(flex: 5, child: _buildPanelMarca()),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 48,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildFormulario(mostrarLogo: !ancho),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 24,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver al sitio'),
                    style: TextButton.styleFrom(
                      foregroundColor: WebTheme.texto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- Panel marca

  Widget _buildPanelMarca() {
    return CustomPaint(
      painter: BannerBackgroundPainter(),
      child: Padding(
        padding: const EdgeInsets.all(56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomPaint(
                  size: const Size(30, 24),
                  painter: MountainLogoPainter(),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Comarapa Turismo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PANEL DE ADMINISTRACIÓN',
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
              'Gestiona el contenido\ndel municipio',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 46,
                fontFamily: 'serif',
                height: 1.1,
              ),
            ),
            const SizedBox(height: 32),
            _funcion(Icons.place_outlined, 'Lugares, actividades y gastronomía'),
            _funcion(Icons.hotel_outlined, 'Hoteles y restaurantes'),
            _funcion(Icons.calendar_today_outlined, 'Calendario de eventos'),
            _funcion(Icons.people_outline, 'Usuarios y reseñas'),
            const Spacer(),
            Text(
              '© ${DateTime.now().year} Municipio de Comarapa',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _funcion(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            texto,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Formulario

  Widget _buildFormulario({required bool mostrarLogo}) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mostrarLogo) ...[
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: WebTheme.verdeOscuro,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size(30, 24),
                    painter: MountainLogoPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: WebTheme.verdeOscuro,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa con tu cuenta de administrador o editor.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _etiqueta('Correo electrónico'),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              decoration: _decoracion(
                hint: 'admin123@gmail.com',
                icono: Icons.mail_outline,
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'El correo electrónico es obligatorio.';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                  return 'Ingresa un correo electrónico válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _etiqueta('Contraseña'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: _decoracion(
                hint: '••••••••••••',
                icono: Icons.lock_outline,
                sufijo: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es obligatoria.';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _verdeBoton,
                  disabledBackgroundColor: _verdeBoton.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2ECE7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: _verdeBoton, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Acceso restringido a personal autorizado.',
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _decoracion({
    required String hint,
    required IconData icono,
    Widget? sufijo,
  }) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icono, color: Colors.grey.shade500),
      suffixIcon: sufijo,
      filled: true,
      fillColor: WebTheme.fondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: borde(Colors.grey.shade300),
      enabledBorder: borde(Colors.grey.shade300),
      focusedBorder: borde(_verdeBoton, 1.5),
      errorBorder: borde(Colors.red),
      focusedErrorBorder: borde(Colors.red, 1.5),
    );
  }
}
