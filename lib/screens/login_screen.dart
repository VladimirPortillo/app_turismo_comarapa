import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  String? _message;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_limpiarError);
    _passwordController.addListener(_limpiarError);
  }

  void _limpiarError() {
    if (_message != null) {
      setState(() => _message = null);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_limpiarError);
    _passwordController.removeListener(_limpiarError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _traducirErrorAuth(dynamic error) {
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
      if (msg.contains('user already registered') ||
          msg.contains('already exists')) {
        return 'Este correo electrónico ya se encuentra registrado en el sistema.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('weak_password')) {
        return 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Demasiados intentos. Por favor espera unos momentos antes de reintentar.';
      }
      if (msg.contains('user not found')) {
        return 'Usuario no encontrado. Verifica el correo ingresado.';
      }
      if (msg.contains('signup disabled')) {
        return 'El registro de nuevos usuarios se encuentra deshabilitado.';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final service = AuthService(Supabase.instance.client);

      if (_registerMode) {
        final result = await service.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() => _message = result);
        }
      } else {
        await service.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _message = _traducirErrorAuth(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = _traducirErrorAuth(error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 600;

    final Widget content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(context), _buildFormContent(context)],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(color: Colors.white, child: content),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(child: content),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return CustomPaint(
      painter: HeaderBackgroundPainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomPaint(
                      size: const Size(22, 18),
                      painter: MountainLogoPainter(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Comarapa Turismo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Volver al inicio',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _registerMode
                    ? 'REGISTRO DE USUARIO'
                    : 'PANEL DE ADMINISTRACIÓN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _registerMode
                  ? 'Crea tu cuenta para\nel municipio'
                  : 'Gestiona el contenido\ndel municipio',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                fontFamily: 'serif',
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _registerMode ? '' : 'Iniciar sesión',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C3D28),
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _registerMode
                ? 'Regístrate con tu correo para empezar.'
                : 'Ingresa con tu cuenta de administrador o editor.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Correo electrónico',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'admin123@gmail.com',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D52),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'El correo electrónico es obligatorio.';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                return 'Ingresa un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Contraseña',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '••••••••••••',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D52),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D52),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFF2E7D52,
                ).withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                  : Text(
                      _registerMode ? 'Registrarme' : 'Iniciar sesión',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2ECE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2E7D52),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Acceso restringido a personal autorizado.',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      height: 1.5,
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
}

class HeaderBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background color: Deep rich forest green
    paint.color = const Color(0xFF0C3D28);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Mountain silhouettes in the background with very low opacity
    // Left mountain (smaller, back)
    paint.color = Colors.white.withValues(alpha: 0.025);
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.7, size.height)
      ..close();
    canvas.drawPath(path1, paint);

    // Right mountain (larger, front)
    paint.color = Colors.white.withValues(alpha: 0.04);
    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.6, size.height * 0.25)
      ..lineTo(size.width * 1.1, size.height)
      ..close();
    canvas.drawPath(path2, paint);

    // Decorative diagonal accent band at the bottom left:
    // It's a light minty grey-green triangle.
    // Starting on the left side of the header and angling down to the bottom
    paint.color = const Color(0xFFBAD0C1);
    final path3 = Path()
      ..moveTo(0, size.height * 0.84)
      ..lineTo(size.width * 0.58, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MountainLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Starts bottom left, goes up to main peak
    path.moveTo(size.width * 0.05, size.height * 0.85);
    path.lineTo(size.width * 0.4, size.height * 0.25);
    // Valley
    path.lineTo(size.width * 0.62, size.height * 0.7);
    // Second peak
    path.lineTo(size.width * 0.82, size.height * 0.45);
    // Bottom right
    path.lineTo(size.width * 0.95, size.height * 0.8);

    canvas.drawPath(path, paint);

    // Draw the dot/sun to the left of the main peak
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.35),
      2.2,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
