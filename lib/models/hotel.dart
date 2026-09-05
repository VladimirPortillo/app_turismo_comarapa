class Hotel {
  const Hotel({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    this.direccionReferencia,
    this.precioMin,
    this.precioMax,
    this.servicios = const <String>[],
    this.contactoReservas,
    this.calificacionPromedio = 0,
    this.activo = true,
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
  final num? precioMin;
  final num? precioMax;
  final List<String> servicios;
  final String? contactoReservas;
  final num calificacionPromedio;
  final bool activo;

  factory Hotel.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    return Hotel(
      id: map['id']?.toString(),
      categoriaId: map['categoria_id']?.toString(),
      categoriaNombre: categoria?['nombre']?.toString(),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      direccionReferencia: map['direccion_referencia']?.toString(),
      precioMin: map['precio_min'] as num?,
      precioMax: map['precio_max'] as num?,
      servicios: (map['servicios'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      contactoReservas: map['contacto_reservas']?.toString(),
      calificacionPromedio: (map['calificacion_promedio'] as num?) ?? 0,
      activo: map['activo'] as bool? ?? true,
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
      'direccion_referencia': direccionReferencia,
      'precio_min': precioMin,
      'precio_max': precioMax,
      'servicios': servicios,
      'contacto_reservas': contactoReservas,
      'activo': activo,
    };
  }

  Hotel copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    double? latitud,
    double? longitud,
    String? direccionReferencia,
    num? precioMin,
    num? precioMax,
    List<String>? servicios,
    String? contactoReservas,
    num? calificacionPromedio,
    bool? activo,
  }) {
    return Hotel(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccionReferencia: direccionReferencia ?? this.direccionReferencia,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      servicios: servicios ?? this.servicios,
      contactoReservas: contactoReservas ?? this.contactoReservas,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
      activo: activo ?? this.activo,
    );
  }
}
