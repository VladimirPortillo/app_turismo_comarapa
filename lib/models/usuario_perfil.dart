class UsuarioPerfil {
  const UsuarioPerfil({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final bool activo;

  bool get esAdministrador => rol == 'administrador';

  factory UsuarioPerfil.fromMap(Map<String, dynamic> map) {
    return UsuarioPerfil(
      id: map['id'].toString(),
      nombre: map['nombre']?.toString() ?? '',
      correo: map['correo']?.toString() ?? '',
      rol: map['rol']?.toString() ?? 'editor',
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'activo': activo,
    };
  }

  UsuarioPerfil copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? rol,
    bool? activo,
  }) {
    return UsuarioPerfil(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }
}
