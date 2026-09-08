class Resena {
  const Resena({
    this.id,
    required this.entidad,
    required this.entidadId,
    required this.autorNombre,
    required this.calificacion,
    this.comentario,
    this.createdAt,
  });

  final String? id;
  final String entidad;
  final String entidadId;
  final String autorNombre;
  final int calificacion;
  final String? comentario;
  final DateTime? createdAt;

  factory Resena.fromMap(Map<String, dynamic> map) {
    return Resena(
      id: map['id']?.toString(),
      entidad: map['entidad']?.toString() ?? '',
      entidadId: map['entidad_id']?.toString() ?? '',
      autorNombre: map['autor_nombre']?.toString() ?? '',
      calificacion: (map['calificacion'] as num?)?.toInt() ?? 0,
      comentario: map['comentario']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toWriteMap() {
    return <String, dynamic>{
      'entidad': entidad,
      'entidad_id': entidadId,
      'autor_nombre': autorNombre.trim(),
      'calificacion': calificacion,
      'comentario': (comentario == null || comentario!.trim().isEmpty) ? null : comentario!.trim(),
      'estado_moderacion': 'aprobada',
    };
  }
}
