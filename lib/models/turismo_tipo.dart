/// Coincide con el enum `entidad_categoria` de Supabase para los
/// módulos del MVP (lugar, actividad, gastronomia, hotel).
enum TurismoTipo {
  lugar('lugar', 'Lugares'),
  actividad('actividad', 'Actividades'),
  gastronomia('gastronomia', 'Gastronomía'),
  hotel('hotel', 'Hoteles'),
  evento('evento', 'Eventos'),
  restaurante('restaurante', 'Restaurantes');

  const TurismoTipo(this.entidad, this.etiqueta);

  final String entidad;
  final String etiqueta;

  static TurismoTipo fromEtiqueta(String etiqueta) {
    return TurismoTipo.values.firstWhere(
      (tipo) => tipo.etiqueta == etiqueta,
      orElse: () => TurismoTipo.lugar,
    );
  }
}

const List<String> kNivelesDificultad = ['facil', 'media', 'dificil'];

String dificultadLabel(String valor) {
  switch (valor) {
    case 'media':
      return 'Media';
    case 'dificil':
      return 'Difícil';
    case 'facil':
    default:
      return 'Fácil';
  }
}

String dificultadValor(String label) {
  switch (label) {
    case 'Media':
      return 'media';
    case 'Difícil':
      return 'dificil';
    case 'Fácil':
    default:
      return 'facil';
  }
}
