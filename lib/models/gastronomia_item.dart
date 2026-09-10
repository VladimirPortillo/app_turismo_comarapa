class GastronomiaItem {
  const GastronomiaItem({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    this.restauranteId,
    this.restauranteNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.temporada,
    this.precioReferencial,
    this.activo = true,
  });

  final String? id;
  final String? categoriaId;
  final String? categoriaNombre;
  final String? restauranteId;
  final String? restauranteNombre;
  final String nombre;
  final String descripcion;
  final List<String> imagenes;
  final String? temporada;
  final num? precioReferencial;
  final bool activo;

  factory GastronomiaItem.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    final restaurante = map['restaurantes'] as Map<String, dynamic>?;
    return GastronomiaItem(
      id: map['id']?.toString(),
      categoriaId: map['categoria_id']?.toString(),
      categoriaNombre: categoria?['nombre']?.toString(),
      restauranteId: map['restaurante_id']?.toString(),
      restauranteNombre: restaurante?['nombre']?.toString(),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      temporada: map['temporada']?.toString(),
      precioReferencial: map['precio_referencial'] as num?,
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toWriteMap() {
    return <String, dynamic>{
      'categoria_id': categoriaId,
      'restaurante_id': restauranteId,
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'imagenes': imagenes,
      'temporada': temporada,
      'precio_referencial': precioReferencial,
      'activo': activo,
    };
  }

  GastronomiaItem copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? restauranteId,
    String? restauranteNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    String? temporada,
    num? precioReferencial,
    bool? activo,
  }) {
    return GastronomiaItem(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      restauranteId: restauranteId ?? this.restauranteId,
      restauranteNombre: restauranteNombre ?? this.restauranteNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      temporada: temporada ?? this.temporada,
      precioReferencial: precioReferencial ?? this.precioReferencial,
      activo: activo ?? this.activo,
    );
  }
}
