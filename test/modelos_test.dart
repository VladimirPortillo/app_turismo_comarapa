import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final_360/models/lugar.dart';
import 'package:proyecto_final_360/models/resena.dart';
import 'package:proyecto_final_360/models/usuario_perfil.dart';

void main() {
  group('Resena', () {
    test('toWriteMap limpia espacios y publica la reseña como aprobada', () {
      const resena = Resena(
        entidad: 'lugar',
        entidadId: 'abc',
        autorNombre: '  Ana  ',
        calificacion: 5,
        comentario: '  Muy lindo  ',
      );

      final map = resena.toWriteMap();

      expect(map['autor_nombre'], 'Ana');
      expect(map['comentario'], 'Muy lindo');
      expect(map['estado_moderacion'], 'aprobada');
    });

    test('toWriteMap guarda null si el comentario está vacío', () {
      const resena = Resena(
        entidad: 'hotel',
        entidadId: 'xyz',
        autorNombre: 'Luis',
        calificacion: 3,
        comentario: '   ',
      );

      expect(resena.toWriteMap()['comentario'], isNull);
    });

    test('fromMap tolera campos faltantes', () {
      final resena = Resena.fromMap(<String, dynamic>{'id': 1});

      expect(resena.id, '1');
      expect(resena.calificacion, 0);
      expect(resena.createdAt, isNull);
    });
  });

  group('Lugar', () {
    test('fromMap lee la categoría anidada y convierte números', () {
      final lugar = Lugar.fromMap(<String, dynamic>{
        'id': 7,
        'nombre': 'Mirador',
        'categorias': <String, dynamic>{'nombre': 'Naturaleza'},
        'imagenes': <dynamic>['a.jpg', 'b.jpg'],
        'latitud': -18,
        'longitud': -64,
        'costo_entrada': 10,
      });

      expect(lugar.id, '7');
      expect(lugar.categoriaNombre, 'Naturaleza');
      expect(lugar.imagenes, ['a.jpg', 'b.jpg']);
      expect(lugar.latitud, -18.0);
      expect(lugar.costoEntrada, 10);
      expect(lugar.activo, isTrue);
    });

    test('toWriteMap recorta el nombre y no envía el id', () {
      const lugar = Lugar(id: '1', nombre: '  Cascada  ', descripcion: ' Agua ');

      final map = lugar.toWriteMap();

      expect(map['nombre'], 'Cascada');
      expect(map['descripcion'], 'Agua');
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('UsuarioPerfil', () {
    test('rol por defecto es editor y no es administrador', () {
      final perfil = UsuarioPerfil.fromMap(<String, dynamic>{'id': 'u1'});

      expect(perfil.rol, 'editor');
      expect(perfil.esAdministrador, isFalse);
    });

    test('reconoce al administrador', () {
      final perfil = UsuarioPerfil.fromMap(<String, dynamic>{
        'id': 'u2',
        'rol': 'administrador',
        'activo': true,
      });

      expect(perfil.esAdministrador, isTrue);
    });
  });
}
