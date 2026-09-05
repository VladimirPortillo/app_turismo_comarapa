import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/turismo_tipo.dart';
import '../models/usuario_perfil.dart';
import '../repositories/usuario_repository.dart';
import '../widgets/mode_banner.dart';
import 'about_adaptation_screen.dart';
import 'admin_home_screen.dart';
import 'context/context_lab_screen.dart';
import 'edit_user_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedRoleFilter = 'Todos'; // 'Todos', 'Administradores', 'Editores'
  String _searchQuery = '';
  bool _isSearching = false;
  bool _loading = true;
  UsuarioPerfil? _perfilActual;

  List<UsuarioPerfil> _usuarios = <UsuarioPerfil>[];

  // Datos demo idénticos a la maqueta en caso de no haber conexión o tabla vacía
  static final List<UsuarioPerfil> _demoUsuarios = [
    const UsuarioPerfil(
      id: 'demo-1',
      nombre: 'María Vargas',
      correo: 'admin@comarapa.gob.bo',
      rol: 'administrador',
      activo: true,
    ),
    const UsuarioPerfil(
      id: 'demo-2',
      nombre: 'Jorge Poma',
      correo: 'jorge.turismo@comarapa.gob.bo',
      rol: 'editor',
      activo: true,
    ),
    const UsuarioPerfil(
      id: 'demo-3',
      nombre: 'Lucía Rojas',
      correo: 'lucia.rojas@comarapa.gob.bo',
      rol: 'editor',
      activo: true,
    ),
    const UsuarioPerfil(
      id: 'demo-4',
      nombre: 'Erick Salazar',
      correo: 'erick.s@comarapa.gob.bo',
      rol: 'editor',
      activo: false,
    ),
    const UsuarioPerfil(
      id: 'demo-5',
      nombre: 'Carmen Morales',
      correo: 'carmen.m@comarapa.gob.bo',
      rol: 'editor',
      activo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadUsuarios();
    _loadPerfilActual();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPerfilActual() async {
    try {
      final perfil = await context.read<UsuarioRepository>().fetchCurrent();
      if (mounted) setState(() => _perfilActual = perfil);
    } catch (_) {}
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _loading = true;
    });

    try {
      final repo = context.read<UsuarioRepository>();
      final users = await repo.fetchAll();
      if (!mounted) return;

      setState(() {
        _usuarios = users.isNotEmpty ? users : List.from(_demoUsuarios);
        _loading = false;
      });
    } catch (_) {
      // Fallback a demo users para asegurar fidelidad visual en offline/demo
      if (!mounted) return;
      setState(() {
        _usuarios = List.from(_demoUsuarios);
        _loading = false;
      });
    }
  }

  List<UsuarioPerfil> get _filteredUsuarios {
    return _usuarios.where((user) {
      final matchesRole = _selectedRoleFilter == 'Todos' ||
          (_selectedRoleFilter == 'Administradores' && user.esAdministrador) ||
          (_selectedRoleFilter == 'Editores' && !user.esAdministrador);

      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          user.nombre.toLowerCase().contains(query) ||
          user.correo.toLowerCase().contains(query);

      return matchesRole && matchesSearch;
    }).toList();
  }

  int _getCountForRole(String role) {
    if (role == 'Todos') return _usuarios.length;
    if (role == 'Administradores') {
      return _usuarios.where((u) => u.esAdministrador).length;
    }
    return _usuarios.where((u) => !u.esAdministrador).length;
  }

  Color _getAvatarBgColor(UsuarioPerfil user) {
    if (!user.activo) {
      return const Color(0xFF9CA3AF); // Gris para inactivo
    }
    if (user.esAdministrador) {
      return const Color(0xFF26674B); // Verde para admin
    }
    return const Color(0xFFA6692B); // Ocre/marrón para editor
  }

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _openEditUser(UsuarioPerfil user) async {
    final updatedUser = await Navigator.push<UsuarioPerfil>(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _usuarios[index] = updatedUser;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario "${updatedUser.nombre}" actualizado con éxito.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showInviteDialog() async {
    final nombreCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    String rolSeleccionado = 'editor';

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF26674B)),
                  SizedBox(width: 10),
                  Text(
                    'Invitar usuario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C3D28),
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre completo',
                        hintText: 'Ej. Juan Pérez',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'usuario@comarapa.gob.bo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Asignar rol inicial:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Editor')),
                            selected: rolSeleccionado == 'editor',
                            selectedColor: const Color(0xFF26674B),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: rolSeleccionado == 'editor' ? Colors.white : const Color(0xFF374151),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setDialogState(() => rolSeleccionado = 'editor');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Administrador')),
                            selected: rolSeleccionado == 'administrador',
                            selectedColor: const Color(0xFF26674B),
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: rolSeleccionado == 'administrador' ? Colors.white : const Color(0xFF374151),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setDialogState(() => rolSeleccionado = 'administrador');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF26674B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final correo = correoCtrl.text.trim();
                    if (nombre.isEmpty || correo.isEmpty || !correo.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un nombre y correo válidos.')),
                      );
                      return;
                    }

                    try {
                      final repo = context.read<UsuarioRepository>();
                      await repo.createUsuario(
                        nombre: nombre,
                        correo: correo,
                        rol: rolSeleccionado,
                      );
                    } catch (_) {
                      // Fallback local en caso de restricciones RLS o modo offline
                    }

                    if (mounted) {
                      setState(() {
                        _usuarios.insert(
                          0,
                          UsuarioPerfil(
                            id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                            nombre: nombre,
                            correo: correo,
                            rol: rolSeleccionado,
                            activo: true,
                          ),
                        );
                      });
                    }

                    Navigator.pop(dialogCtx, true);
                  },
                  child: const Text('Enviar invitación'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación enviada a ${correoCtrl.text.trim()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilNombre = _perfilActual?.nombre.isNotEmpty == true
        ? _perfilActual!.nombre
        : 'María Vargas';
    final userInitials = _getInitials(perfilNombre);

    final filteredList = _filteredUsuarios;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF9F6),
      drawer: _buildDrawer(perfilNombre),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        backgroundColor: const Color(0xFF26674B),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Invitar usuario',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModeBanner(),
            _buildTopAppBar(userInitials),
            const SizedBox(height: 12),
            _buildModuleTabs(),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            _buildSubFiltersRow(),
            if (_isSearching) _buildSearchInput(),
            const SizedBox(height: 12),
            Expanded(child: _buildListBody(filteredList)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(String initials) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_scaffoldKey.currentState?.hasDrawer == true) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C3D28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PANEL ADMIN',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Usuarios',
                    style: TextStyle(
                      color: Color(0xFF0C3D28),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      fontFamily: 'serif',
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE2ECE7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF1B5A3F),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTabs() {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildModulePill('Lugares', TurismoTipo.lugar),
              _buildModulePill('Actividades', TurismoTipo.actividad),
              _buildModulePill('Gastronomía', TurismoTipo.gastronomia),
              _buildModulePill('Hoteles', TurismoTipo.hotel),
              _buildModulePill('Eventos', TurismoTipo.evento),
              _buildModulePill('Restaurantes', TurismoTipo.restaurante),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Indicador de barra de desplazamiento horizontal idéntico al de la maqueta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.arrow_left, size: 14, color: Colors.grey.shade400),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.45,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Icon(Icons.arrow_right, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModulePill(String title, TurismoTipo tipo) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHomeScreen(initialTipo: tipo),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubFiltersRow() {
    final filters = ['Todos', 'Administradores', 'Editores'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: filters.map((filter) {
              final isSelected = _selectedRoleFilter == filter;
              final count = _getCountForRole(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRoleFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF26674B) : const Color(0xFFE8F4EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$filter · $count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF26674B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar usuario por nombre o correo...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildListBody(List<UsuarioPerfil> filteredList) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off_outlined, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron usuarios',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              Text(
                'Prueba cambiando el filtro de búsqueda o el rol seleccionado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
      children: [
        ...filteredList.map((user) => _buildUserCard(user)),
        const SizedBox(height: 10),
        _buildInfoBanner(),
      ],
    );
  }

  Widget _buildUserCard(UsuarioPerfil user) {
    final avatarColor = _getAvatarBgColor(user);
    final initials = _getInitials(user.nombre);

    return GestureDetector(
      onTap: () => _openEditUser(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar circular con iniciales
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Nombre, correo y badges de estado/rol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.correo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Fila con Badges de Rol y Activo/Inactivo
                  Row(
                    children: [
                      // Badge de Rol
                      if (user.esAdministrador)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4D36),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Administrador',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF0E6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Editor',
                            style: TextStyle(
                              color: Color(0xFFA6692B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),

                      // Badge de Estado (Activo / Inactivo)
                      if (user.activo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F4EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: Color(0xFF26674B),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Activo',
                                style: TextStyle(
                                  color: Color(0xFF26674B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: Color(0xFF9CA3AF),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Inactivo',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Acción a la derecha (lápiz para activos, ojo/ver para inactivos)
            IconButton(
              icon: Icon(
                user.activo ? Icons.edit_outlined : Icons.visibility_outlined,
                color: const Color(0xFF26674B),
                size: 22,
              ),
              onPressed: () => _openEditUser(user),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6EAE0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF26674B), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solo un administrador puede cambiar el rol de otro usuario. '
              'Desactivar una cuenta le quita el acceso al panel sin borrar su historial.',
              style: TextStyle(
                color: Color(0xFF26674B),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String name) {
    return Drawer(
      backgroundColor: const Color(0xFFFAF9F6),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0C3D28)),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(color: Color(0xFFE2ECE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Color(0xFF1B5A3F), fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(_perfilActual?.correo ?? 'admin@comarapa.gob.bo'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Panel Principal'),
                  subtitle: const Text('Gestión de atractivos y servicios'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hotel_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Hoteles'),
                  subtitle: const Text('Hospedajes y alojamientos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(initialTipo: TurismoTipo.hotel),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Eventos'),
                  subtitle: const Text('Ferias y fiestas patronales'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(initialTipo: TurismoTipo.evento),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('Administrar Restaurantes'),
                  subtitle: const Text('Comida típica y locales'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(initialTipo: TurismoTipo.restaurante),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt, color: Color(0xFF26674B)),
                  title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF26674B))),
                  subtitle: const Text('Administradores y editores'),
                  selected: true,
                  selectedTileColor: const Color(0xFFE8F4EC),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('1. Mis registros (BD)'),
                  subtitle: const Text('CRUD de la Sesión 1'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Color(0xFF1B5A3F)),
                  title: const Text('2. Conexión con el mundo'),
                  subtitle: const Text('GPS, clima y mapa'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContextLabScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune, color: Color(0xFF1B5A3F)),
                  title: const Text('3. Preferencias de usuario'),
                  subtitle: const Text('Persistencia local SharedPreferences'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.design_services_outlined, color: Color(0xFF1B5A3F)),
                  title: const Text('4. Adaptar a mi proyecto'),
                  subtitle: const Text('Acerca del proyecto'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAdaptationScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Turismo Comarapa v1.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
