import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/usuario_perfil.dart';
import '../repositories/usuario_repository.dart';
import '../widgets/paginador.dart';
import 'web_theme.dart';

const Color _verde = Color(0xFF26674B);
const Color _ocre = Color(0xFFA6692B);

enum _FiltroRol {
  todos('Todos'),
  administradores('Administradores'),
  editores('Editores');

  const _FiltroRol(this.label);
  final String label;
}

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  if (partes.isEmpty || partes.first.isEmpty) return 'U';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
}

/// Mismo código de colores que la app: verde admin, ocre editor, gris inactivo.
Color _colorAvatar(UsuarioPerfil u) {
  if (!u.activo) return const Color(0xFF9CA3AF);
  return u.esAdministrador ? _verde : _ocre;
}

/// Gestión de usuarios para el panel de administración web.
/// Se muestra dentro de [WebAdminScreen], en el área de contenido.
class WebAdminUsersPanel extends StatefulWidget {
  const WebAdminUsersPanel({super.key, required this.perfilActual});

  /// Usuario con sesión iniciada (para no permitirle quitarse permisos).
  final UsuarioPerfil? perfilActual;

  @override
  State<WebAdminUsersPanel> createState() => _WebAdminUsersPanelState();
}

class _WebAdminUsersPanelState extends State<WebAdminUsersPanel> {
  final TextEditingController _searchController = TextEditingController();

  _FiltroRol _filtro = _FiltroRol.todos;
  String _query = '';
  int _pagina = 0;
  bool _loading = true;
  String? _error;
  List<UsuarioPerfil> _usuarios = <UsuarioPerfil>[];

  /// Ids con un cambio en curso (para deshabilitar sus controles).
  final Set<String> _guardando = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _pagina = 0;
      });
    });
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usuarios = await context.read<UsuarioRepository>().fetchAll();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  bool _esYo(UsuarioPerfil u) => u.id == widget.perfilActual?.id;

  List<UsuarioPerfil> get _visibles {
    return _usuarios.where((u) {
      final okRol = switch (_filtro) {
        _FiltroRol.todos => true,
        _FiltroRol.administradores => u.esAdministrador,
        _FiltroRol.editores => !u.esAdministrador,
      };
      final okTexto =
          _query.isEmpty ||
          u.nombre.toLowerCase().contains(_query) ||
          u.correo.toLowerCase().contains(_query);
      return okRol && okTexto;
    }).toList();
  }

  void _avisar(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        width: 480,
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  void _reemplazar(UsuarioPerfil actualizado) {
    final i = _usuarios.indexWhere((u) => u.id == actualizado.id);
    if (i != -1) setState(() => _usuarios[i] = actualizado);
  }

  // ---------------------------------------------------- Cambios rápidos

  Future<void> _cambiarRol(UsuarioPerfil u, String rol) async {
    if (u.rol == rol) return;
    setState(() => _guardando.add(u.id));
    try {
      await context.read<UsuarioRepository>().updateRol(u.id, rol);
      _reemplazar(u.copyWith(rol: rol));
      _avisar(
        '"${u.nombre}" ahora es ${rol == 'administrador' ? 'Administrador' : 'Editor'}.',
      );
    } catch (error) {
      _avisar('No se pudo cambiar el rol: $error', error: true);
    } finally {
      if (mounted) setState(() => _guardando.remove(u.id));
    }
  }

  Future<void> _cambiarActivo(UsuarioPerfil u) async {
    final nuevo = !u.activo;
    setState(() => _guardando.add(u.id));
    try {
      await context.read<UsuarioRepository>().setActivo(u.id, nuevo);
      _reemplazar(u.copyWith(activo: nuevo));
      _avisar(
        nuevo
            ? '"${u.nombre}" puede volver a iniciar sesión.'
            : 'Se suspendió el acceso de "${u.nombre}".',
      );
    } catch (error) {
      _avisar('No se pudo actualizar: $error', error: true);
    } finally {
      if (mounted) setState(() => _guardando.remove(u.id));
    }
  }

  Future<void> _editar(UsuarioPerfil u) async {
    final actualizado = await showDialog<UsuarioPerfil>(
      context: context,
      builder: (_) => _EditarUsuarioDialog(usuario: u, esYo: _esYo(u)),
    );
    if (actualizado == null) return;
    _reemplazar(actualizado);
    _avisar('Usuario "${actualizado.nombre}" actualizado con éxito.');
  }

  Future<void> _crear() async {
    final resultado = await showDialog<({String nombre, String? advertencia})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CrearUsuarioDialog(),
    );
    if (resultado == null) return;
    await _cargar();
    if (!mounted) return;
    final advertencia = resultado.advertencia;
    if (advertencia != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(advertencia),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          width: 560,
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      _avisar('Usuario "${resultado.nombre}" registrado con éxito.');
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('No se pudo cargar la lista de usuarios.'),
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final admins = _usuarios.where((u) => u.esAdministrador).length;
    final inactivos = _usuarios.where((u) => !u.activo).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Usuarios',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: WebTheme.verdeOscuro,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Administradores y editores con acceso al panel.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _stat(
                'Total',
                _usuarios.length,
                Icons.group_outlined,
                WebTheme.verdeOscuro,
              ),
              const SizedBox(width: 16),
              _stat(
                'Administradores',
                admins,
                Icons.admin_panel_settings_outlined,
                _verde,
              ),
              const SizedBox(width: 16),
              _stat(
                'Editores',
                _usuarios.length - admins,
                Icons.edit_note,
                _ocre,
              ),
              const SizedBox(width: 16),
              _stat('Sin acceso', inactivos, Icons.block, Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 24),
          _buildToolbar(admins),
          const SizedBox(height: 16),
          _buildTabla(paginar(_visibles, _pagina)),
          Paginador(
            pagina: _pagina,
            total: _visibles.length,
            color: _verde,
            onCambiar: (p) => setState(() => _pagina = p),
          ),
        ],
      ),
    );
  }

  Widget _stat(String titulo, int valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valor',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(titulo, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(int admins) {
    final conteo = {
      _FiltroRol.todos: _usuarios.length,
      _FiltroRol.administradores: admins,
      _FiltroRol.editores: _usuarios.length - admins,
    };
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Row(
      children: [
        SegmentedButton<_FiltroRol>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: WebTheme.verdeClaro,
            selectedForegroundColor: WebTheme.verde,
          ),
          segments: [
            for (final f in _FiltroRol.values)
              ButtonSegment(value: f, label: Text('${f.label} · ${conteo[f]}')),
          ],
          selected: {_filtro},
          onSelectionChanged: (s) => setState(() {
            _filtro = s.first;
            _pagina = 0;
          }),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar por nombre o correo...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _searchController.clear,
                    ),
              filled: true,
              fillColor: Colors.white,
              border: borde,
              enabledBorder: borde,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _cargar,
          icon: const Icon(Icons.refresh),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _crear,
          style: FilledButton.styleFrom(
            backgroundColor: _verde,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text(
            'Crear usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static const double _anchoRol = 190;
  static const double _anchoAcceso = 170;
  static const double _anchoAcciones = 60;

  Widget _buildTabla(List<UsuarioPerfil> usuarios) {
    final cabecera = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: Colors.grey.shade600,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: WebTheme.fondo,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('USUARIO', style: cabecera)),
                Expanded(flex: 3, child: Text('CORREO', style: cabecera)),
                SizedBox(
                  width: _anchoRol,
                  child: Text('ROL', style: cabecera),
                ),
                SizedBox(
                  width: _anchoAcceso,
                  child: Text('ACCESO', style: cabecera),
                ),
                const SizedBox(width: _anchoAcciones),
              ],
            ),
          ),
          if (usuarios.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se encontraron usuarios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: WebTheme.texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prueba cambiando la búsqueda o el rol seleccionado.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < usuarios.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
              _buildFila(usuarios[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildFila(UsuarioPerfil u) {
    final yo = _esYo(u);
    final ocupado = _guardando.contains(u.id);
    // Nadie puede quitarse a sí mismo el rol de administrador ni el acceso.
    const motivoYo = 'No puedes cambiar tu propio rol ni tu acceso.';

    return InkWell(
      onTap: () => _editar(u),
      hoverColor: const Color(0xFFF7FAF8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: _colorAvatar(u),
                    child: Text(
                      _iniciales(u.nombre),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      u.nombre.isEmpty ? 'Sin nombre' : u.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: u.activo
                            ? const Color(0xFF1F2937)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  if (yo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: WebTheme.verdeClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tú',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: WebTheme.verde,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                u.correo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            SizedBox(
              width: _anchoRol,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: yo ? motivoYo : 'Cambiar rol',
                  child: PopupMenuButton<String>(
                    enabled: !yo && !ocupado,
                    initialValue: u.rol,
                    onSelected: (rol) => _cambiarRol(u, rol),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editor', child: Text('Editor')),
                      PopupMenuItem(
                        value: 'administrador',
                        child: Text('Administrador'),
                      ),
                    ],
                    child: _RolBadge(u, conFlecha: !yo),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _anchoAcceso,
              child: Tooltip(
                message: yo
                    ? motivoYo
                    : (u.activo ? 'Suspender acceso' : 'Permitir acceso'),
                child: Row(
                  children: [
                    Switch(
                      value: u.activo,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _verde,
                      onChanged: yo || ocupado
                          ? null
                          : (_) => _cambiarActivo(u),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      u.activo ? 'Activo' : 'Suspendido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: u.activo ? _verde : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: _anchoAcciones,
              child: Align(
                alignment: Alignment.centerRight,
                child: ocupado
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _editar(u),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: _verde,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolBadge extends StatelessWidget {
  const _RolBadge(this.usuario, {this.conFlecha = false});

  final UsuarioPerfil usuario;
  final bool conFlecha;

  @override
  Widget build(BuildContext context) {
    final admin = usuario.esAdministrador;
    final color = admin ? Colors.white : _ocre;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: admin ? const Color(0xFF1B4D36) : const Color(0xFFFBF0E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            admin ? 'Administrador' : 'Editor',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (conFlecha) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}

// ============================================================ Diálogos

InputDecoration _decoracion(String label, {String? hint, Widget? sufijo}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: sufijo,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

/// Selector de rol con la descripción de permisos de cada uno.
class _SelectorRol extends StatelessWidget {
  const _SelectorRol({
    required this.rol,
    required this.onChanged,
    this.habilitado = true,
  });

  final String rol;
  final ValueChanged<String> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    Widget opcion(String valor, String titulo, String detalle, IconData icono) {
      final sel = rol == valor;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: habilitado ? () => onChanged(valor) : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? WebTheme.verdeClaro : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? _verde : Colors.grey.shade300,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Opacity(
              opacity: habilitado || sel ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icono,
                        size: 20,
                        color: sel ? _verde : WebTheme.texto,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel ? _verde : WebTheme.texto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detalle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        opcion(
          'editor',
          'Editor',
          'Crea y edita lugares, hoteles, eventos...',
          Icons.edit_note,
        ),
        const SizedBox(width: 12),
        opcion(
          'administrador',
          'Administrador',
          'Además, gestiona usuarios y roles.',
          Icons.admin_panel_settings_outlined,
        ),
      ],
    );
  }
}

class _EditarUsuarioDialog extends StatefulWidget {
  const _EditarUsuarioDialog({required this.usuario, required this.esYo});

  final UsuarioPerfil usuario;
  final bool esYo;

  @override
  State<_EditarUsuarioDialog> createState() => _EditarUsuarioDialogState();
}

class _EditarUsuarioDialogState extends State<_EditarUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario.nombre);
  late String _rol = widget.usuario.rol;
  late bool _activo = widget.usuario.activo;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  /// Mismas reglas que el formulario de la app.
  String? _validarNombre(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre completo es obligatorio.';
    if (v.length < 3) return 'El nombre debe tener al menos 3 caracteres.';
    if (v.length > 80) return 'El nombre no puede superar los 80 caracteres.';
    if (!RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]').hasMatch(v)) {
      return 'El nombre debe contener al menos una letra.';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await context.read<UsuarioRepository>().updatePerfil(
        id: widget.usuario.id,
        nombre: _nombre.text,
        rol: _rol,
        activo: _activo,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        widget.usuario.copyWith(
          nombre: _nombre.text.trim(),
          rol: _rol,
          activo: _activo,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _colorAvatar(u),
            child: Text(
              _iniciales(u.nombre),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Editar usuario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: WebTheme.verdeOscuro,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombre,
                autofocus: true,
                decoration: _decoracion('Nombre completo'),
                validator: _validarNombre,
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: u.correo,
                enabled: false,
                decoration: _decoracion('Correo electrónico (solo lectura)'),
              ),
              const SizedBox(height: 4),
              Text(
                'Es el correo con el que inicia sesión.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rol',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _SelectorRol(
                rol: _rol,
                habilitado: !widget.esYo,
                onChanged: (r) => setState(() => _rol = r),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.white,
                activeTrackColor: _verde,
                title: const Text(
                  'Acceso al panel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _activo
                      ? 'Activo · puede iniciar sesión en el panel de administración.'
                      : 'Inactivo · acceso temporalmente suspendido.',
                ),
                value: _activo,
                onChanged: widget.esYo
                    ? null
                    : (v) => setState(() => _activo = v),
              ),
              if (widget.esYo)
                Text(
                  'No puedes cambiar tu propio rol ni tu acceso.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _verde),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}

class _CrearUsuarioDialog extends StatefulWidget {
  const _CrearUsuarioDialog();

  @override
  State<_CrearUsuarioDialog> createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<_CrearUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  String _rol = 'editor';
  bool _creando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Mismos mensajes que la app.
  String _traducirError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('user already registered') ||
          msg.contains('already exists')) {
        return 'Ese correo ya está registrado en el sistema.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('weak_password')) {
        return 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (msg.contains('invalid email')) {
        return 'El formato de correo electrónico es inválido.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Demasiados intentos. Espera unos momentos y vuelve a intentar.';
      }
      return 'Error al registrar: ${error.message}';
    }
    if (error is PostgrestException) {
      return 'Error al guardar en la base de datos: ${error.message}';
    }
    final e = error.toString().toLowerCase();
    if (e.contains('socketexception') ||
        e.contains('connection refused') ||
        e.contains('network is unreachable') ||
        e.contains('clientexception') ||
        e.contains('failed host lookup')) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión a internet.';
    }
    if (e.contains('timeout')) {
      return 'El servidor tardó demasiado en responder. Inténtalo nuevamente.';
    }
    return 'Ocurrió un error inesperado al registrar el usuario: $error';
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _creando = true;
      _error = null;
    });

    // Igual que en la app: un cliente aislado (sin persistencia) para el
    // alta, porque signUp() con el cliente principal reemplazaría la sesión
    // del administrador. Flujo "implicit": no hay redirect que canjear.
    final config = context.read<AppConfig>();
    final usuarioRepo = context.read<UsuarioRepository>();
    final tempClient = SupabaseClient(
      config.supabaseUrl,
      config.supabasePublishableKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    String? nuevoId;
    try {
      final response = await tempClient.auth.signUp(
        email: _correo.text.trim(),
        password: _password.text,
        data: {'nombre': _nombre.text.trim()},
      );
      nuevoId = response.user?.id;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creando = false;
        _error = _traducirError(error);
      });
      return;
    } finally {
      await tempClient.dispose();
    }

    // La cuenta queda como "editor" (trigger de la BD). Si falla el ascenso
    // a administrador, se avisa en lugar de ocultar que sí se creó.
    String? advertencia;
    if (nuevoId != null && _rol == 'administrador') {
      try {
        await usuarioRepo.updateRol(nuevoId, 'administrador');
      } catch (_) {
        advertencia =
            'El usuario se creó, pero no se pudo asignar el rol de Administrador: '
            'tu propia cuenta todavía no tiene ese rol en la base de datos. '
            'Quedó registrado como Editor; puedes cambiarlo más tarde desde la tabla.';
      }
    }

    if (!mounted) return;
    Navigator.pop(context, (
      nombre: _nombre.text.trim(),
      advertencia: advertencia,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: _verde),
          SizedBox(width: 10),
          Text(
            'Crear usuario',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: WebTheme.verdeOscuro,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: _decoracion(
                  'Nombre completo',
                  hint: 'Ej. Juan Pérez',
                ),
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? 'Ingresa un nombre válido.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _decoracion(
                  'Correo electrónico',
                  hint: 'usuario@comarapa.gob.bo',
                ),
                validator: (v) =>
                    RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Ingresa un correo válido.',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _ocultarPassword,
                onFieldSubmitted: (_) => _crear(),
                decoration: _decoracion(
                  'Contraseña',
                  hint: 'Mínimo 6 caracteres',
                  sufijo: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                ),
                validator: (v) => (v?.length ?? 0) < 6
                    ? 'La contraseña debe tener al menos 6 caracteres.'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Rol inicial',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _SelectorRol(
                rol: _rol,
                onChanged: (r) => setState(() => _rol = r),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _verde),
          onPressed: _creando ? null : _crear,
          child: _creando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Crear usuario'),
        ),
      ],
    );
  }
}
