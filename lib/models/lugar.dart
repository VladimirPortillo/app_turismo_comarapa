class Lugar {
  const Lugar({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    this.direccionReferencia,
    this.dificultad = 'facil',
    this.tiempoVisitaMin,
    this.costoEntrada = 0,
    this.mejorEpoca,
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
  final String dificultad;
  final int? tiempoVisitaMin;
  final num costoEntrada;
  final String? mejorEpoca;
  final bool activo;

  factory Lugar.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    return Lugar(
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
      dificultad: map['dificultad']?.toString() ?? 'facil',
      tiempoVisitaMin: (map['tiempo_visita_min'] as num?)?.toInt(),
      costoEntrada: (map['costo_entrada'] as num?) ?? 0,
      mejorEpoca: map['mejor_epoca']?.toString(),
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
      'dificultad': dificultad,
      'tiempo_visita_min': tiempoVisitaMin,
      'costo_entrada': costoEntrada,
      'mejor_epoca': mejorEpoca,
      'activo': activo,
    };
  }

  Lugar copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    double? latitud,
    double? longitud,
    String? direccionReferencia,
    String? dificultad,
    int? tiempoVisitaMin,
    num? costoEntrada,
    String? mejorEpoca,
    bool? activo,
  }) {
    return Lugar(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccionReferencia: direccionReferencia ?? this.direccionReferencia,
      dificultad: dificultad ?? this.dificultad,
      tiempoVisitaMin: tiempoVisitaMin ?? this.tiempoVisitaMin,
      costoEntrada: costoEntrada ?? this.costoEntrada,
      mejorEpoca: mejorEpoca ?? this.mejorEpoca,
      activo: activo ?? this.activo,
    );
  }
}
