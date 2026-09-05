class Restaurante {
  const Restaurante({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    this.direccionReferencia,
    this.horarioAtencion,
    this.precioReferencial,
    this.contacto,
    this.calificacionPromedio = 0,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? categoriaId;
  final String? categoriaNombre;
  final String nombre;
  final String descripcion;
  final List<String> imagenes;
  final double? latitud;
  final double? longitud;
  final String? direccionReferencia;
  final String? horarioAtencion;
  final num? precioReferencial;
  final String? contacto;
  final num calificacionPromedio;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Restaurante.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;

    return Restaurante(
      id: map['id']?.toString(),
      categoriaId: map['categoria_id']?.toString(),
      categoriaNombre: categoria?['nombre']?.toString() ?? map['categoria_nombre']?.toString(),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      direccionReferencia: map['direccion_referencia']?.toString(),
      horarioAtencion: map['horario_atencion']?.toString(),
      precioReferencial: map['precio_referencial'] as num?,
      contacto: map['contacto']?.toString(),
      calificacionPromedio: (map['calificacion_promedio'] as num?) ?? 0,
      activo: map['activo'] as bool? ?? true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toWriteMap() {
    return <String, dynamic>{
      'categoria_id': categoriaId,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'imagenes': imagenes,
      'latitud': latitud,
      'longitud': longitud,
      'direccion_referencia': direccionReferencia?.trim(),
      'horario_atencion': horarioAtencion?.trim(),
      'precio_referencial': precioReferencial,
      'contacto': contacto?.trim(),
      'calificacion_promedio': calificacionPromedio,
      'activo': activo,
    };
  }

  Restaurante copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    double? latitud,
    double? longitud,
    String? direccionReferencia,
    String? horarioAtencion,
    num? precioReferencial,
    String? contacto,
    num? calificacionPromedio,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurante(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccionReferencia: direccionReferencia ?? this.direccionReferencia,
      horarioAtencion: horarioAtencion ?? this.horarioAtencion,
      precioReferencial: precioReferencial ?? this.precioReferencial,
      contacto: contacto ?? this.contacto,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
