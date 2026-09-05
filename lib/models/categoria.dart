class Categoria {
  const Categoria({
    required this.id,
    required this.entidad,
    required this.nombre,
    this.icono,
    this.orden = 0,
    this.activo = true,
  });

  final String id;
  final String entidad;
  final String nombre;
  final String? icono;
  final int orden;
  final bool activo;

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'].toString(),
      entidad: map['entidad']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      icono: map['icono']?.toString(),
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      activo: map['activo'] as bool? ?? true,
    );
  }
}
