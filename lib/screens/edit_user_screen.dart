import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario_perfil.dart';
import '../repositories/usuario_repository.dart';

class EditUserScreen extends StatefulWidget {
  final UsuarioPerfil user;

  const EditUserScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  late String _selectedRol;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user.nombre);
    _correoController = TextEditingController(text: widget.user.correo);
    _selectedRol = widget.user.rol;
    _isActive = widget.user.activo;

    _nombreController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor() {
    if (!_isActive) {
      return const Color(0xFF9CA3AF);
    }
    if (_selectedRol == 'administrador') {
      return const Color(0xFF26674B);
    }
    return const Color(0xFFA6692B);
  }

  Future<void> _guardarCambios() async {
    final nuevoNombre = _nombreController.text.trim();
    if (nuevoNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre completo no puede estar vacío.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = context.read<UsuarioRepository>();
      // Si no es un usuario puramente demo local, persistir en Supabase
      if (!widget.user.id.startsWith('demo-') && !widget.user.id.startsWith('temp-')) {
        await repo.updatePerfil(
          id: widget.user.id,
          nombre: nuevoNombre,
          rol: _selectedRol,
          activo: _isActive,
        );
      }

      if (!mounted) return;

      final updatedUser = widget.user.copyWith(
        nombre: nuevoNombre,
        rol: _selectedRol,
        activo: _isActive,
      );

      Navigator.pop(context, updatedUser);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _nombreController.text.trim().isNotEmpty
        ? _nombreController.text.trim()
        : widget.user.nombre;
    final initials = _getInitials(displayName);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con botón volver, subtítulo y título
            _buildTopBar(displayName),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Formulario scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera con avatar grande y nombre
                    _buildProfileHeader(initials, displayName),
                    const SizedBox(height: 28),

                    // Campo: Nombre completo
                    _buildNombreField(),
                    const SizedBox(height: 20),

                    // Campo: Correo electrónico
                    _buildCorreoField(),
                    const SizedBox(height: 24),

                    // Selector: Rol
                    _buildRolSelector(),
                    const SizedBox(height: 24),

                    // Tarjeta: Permisos por rol
                    _buildPermisosCard(),
                    const SizedBox(height: 20),

                    // Tarjeta: Acceso al panel (Switch)
                    _buildAccesoPanelCard(),
                  ],
                ),
              ),
            ),

            // Barra inferior con botones Cancelar y Guardar cambios
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuarios · $displayName',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Editar usuario',
                  style: TextStyle(
                    color: Color(0xFF0C3D28),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String initials, String displayName) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _getAvatarColor(),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Invitado hace 3 meses',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNombreField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre completo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: _nombreController,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorreoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Correo electrónico',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: _correoController,
            readOnly: true,
            style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Es el correo con el que inicia sesión; para cambiarlo hay que reenviar una invitación.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildRolSelector() {
    final isAdmin = _selectedRol == 'administrador';
    final isEditor = _selectedRol == 'editor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rol',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5F1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Opción: Administrador
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRol = 'administrador'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFF26674B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Administrador',
                      style: TextStyle(
                        color: isAdmin ? Colors.white : const Color(0xFF4B5563),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Opción: Editor
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRol = 'editor'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEditor ? const Color(0xFF26674B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Editor',
                      style: TextStyle(
                        color: isEditor ? Colors.white : const Color(0xFF4B5563),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 6),
            Text(
              'Solo un administrador puede cambiar este campo.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermisosCard() {
    final isAdmin = _selectedRol == 'administrador';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permisos por rol',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Permiso 1: Crear y editar lugares...
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 18, color: Color(0xFF26674B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Crear y editar lugares, hoteles, eventos...',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),

              // Permiso 2: Gestionar usuarios y roles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isAdmin ? Icons.check : Icons.close,
                      size: 18,
                      color: isAdmin ? const Color(0xFF26674B) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gestionar usuarios y roles (solo administrador)',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccesoPanelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acceso al panel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isActive
                      ? 'Activo · puede iniciar sesión en el panel de administración.'
                      : 'Inactivo · acceso temporalmente suspendido.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF26674B),
            onChanged: (val) => setState(() => _isActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // Botón Cancelar
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1F2937),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Botón Guardar cambios
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26674B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
