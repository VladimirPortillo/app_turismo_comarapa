/// Registro único (singleton) con la información general del municipio,
/// tabla `public.municipio` en Supabase.
class Municipio {
  const Municipio({
    this.nombre = 'Comarapa',
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    this.poblacion,
    this.altitudMsnm,
    this.clima,
  });

  final String nombre;
  final String descripcion;
  final List<String> imagenes;
  final double? latitud;
  final double? longitud;
  final int? poblacion;
  final int? altitudMsnm;
  final String? clima;

  factory Municipio.fromMap(Map<String, dynamic> map) {
    return Municipio(
      nombre: map['nombre']?.toString() ?? 'Comarapa',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      poblacion: (map['poblacion'] as num?)?.toInt(),
      altitudMsnm: (map['altitud_msnm'] as num?)?.toInt(),
      clima: map['clima']?.toString(),
    );
  }
}
