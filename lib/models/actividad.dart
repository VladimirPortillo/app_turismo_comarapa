class Actividad {
  const Actividad({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    this.dificultad = 'facil',
    this.duracionMin,
    this.precioReferencial,
    this.operadorContacto,
    this.capacidadMaxima,
    this.temporada,
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
  final String dificultad;
  final int? duracionMin;
  final num? precioReferencial;
  final String? operadorContacto;
  final int? capacidadMaxima;
  final String? temporada;
  final bool activo;

  factory Actividad.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    return Actividad(
      id: map['id']?.toString(),
      categoriaId: map['categoria_id']?.toString(),
      categoriaNombre: categoria?['nombre']?.toString(),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      dificultad: map['dificultad']?.toString() ?? 'facil',
      duracionMin: (map['duracion_min'] as num?)?.toInt(),
      precioReferencial: map['precio_referencial'] as num?,
      operadorContacto: map['operador_contacto']?.toString(),
      capacidadMaxima: (map['capacidad_maxima'] as num?)?.toInt(),
      temporada: map['temporada']?.toString(),
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
      'dificultad': dificultad,
      'duracion_min': duracionMin,
      'precio_referencial': precioReferencial,
      'operador_contacto': operadorContacto,
      'capacidad_maxima': capacidadMaxima,
      'temporada': temporada,
      'activo': activo,
    };
  }

  Actividad copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    double? latitud,
    double? longitud,
    String? dificultad,
    int? duracionMin,
    num? precioReferencial,
    String? operadorContacto,
    int? capacidadMaxima,
    String? temporada,
    bool? activo,
  }) {
    return Actividad(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      dificultad: dificultad ?? this.dificultad,
      duracionMin: duracionMin ?? this.duracionMin,
      precioReferencial: precioReferencial ?? this.precioReferencial,
      operadorContacto: operadorContacto ?? this.operadorContacto,
      capacidadMaxima: capacidadMaxima ?? this.capacidadMaxima,
      temporada: temporada ?? this.temporada,
      activo: activo ?? this.activo,
    );
  }
}
