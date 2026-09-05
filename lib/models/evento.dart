import 'package:flutter/material.dart';

class Evento {
  const Evento({
    this.id,
    this.categoriaId,
    this.categoriaNombre,
    required this.nombre,
    this.descripcion = '',
    this.imagenes = const <String>[],
    this.latitud,
    this.longitud,
    required this.fechaInicio,
    this.fechaFin,
    this.periodicidad = 'anual',
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
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? periodicidad;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get diaFormateado {
    return fechaInicio.day.toString().padLeft(2, '0');
  }

  String get mesAbreviado {
    const meses = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    final m = fechaInicio.month;
    if (m >= 1 && m <= 12) {
      return meses[m - 1];
    }
    return 'ENE';
  }

  Color get badgeBgColor {
    if (!activo) return const Color(0xFFF3F4F6);
    final n = nombre.toLowerCase();
    if (n.contains('durazno')) return const Color(0xFFFBECE2);
    if (n.contains('patronal') || n.contains('agro')) return const Color(0xFFE2F0E8);
    return const Color(0xFFE2F0E8);
  }

  Color get badgeTextColor {
    if (!activo) return const Color(0xFF9CA3AF);
    final n = nombre.toLowerCase();
    if (n.contains('durazno')) return const Color(0xFFB45309);
    if (n.contains('patronal') || n.contains('agro')) return const Color(0xFF26674B);
    return const Color(0xFF26674B);
  }

  factory Evento.fromMap(Map<String, dynamic> map) {
    final categoria = map['categorias'] as Map<String, dynamic>?;
    DateTime inicio = DateTime.now();
    if (map['fecha_inicio'] != null) {
      inicio = DateTime.tryParse(map['fecha_inicio'].toString()) ?? DateTime.now();
    }

    DateTime? fin;
    if (map['fecha_fin'] != null) {
      fin = DateTime.tryParse(map['fecha_fin'].toString());
    }

    return Evento(
      id: map['id']?.toString(),
      categoriaId: map['categoria_id']?.toString(),
      categoriaNombre: categoria?['nombre']?.toString() ?? map['categoria_nombre']?.toString(),
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      imagenes: (map['imagenes'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      fechaInicio: inicio,
      fechaFin: fin,
      periodicidad: map['periodicidad']?.toString() ?? 'anual',
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
      'fecha_inicio': fechaInicio.toIso8601String(),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String(),
      'periodicidad': periodicidad,
      'activo': activo,
    };
  }

  Evento copyWith({
    String? id,
    String? categoriaId,
    String? categoriaNombre,
    String? nombre,
    String? descripcion,
    List<String>? imagenes,
    double? latitud,
    double? longitud,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? periodicidad,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Evento(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      periodicidad: periodicidad ?? this.periodicidad,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
