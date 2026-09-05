import 'package:flutter/material.dart';

import '../models/turismo_tipo.dart';
import 'admin_home_screen.dart';

/// Pantalla dedicada para Administrar Restaurantes en el Panel de Administración.
/// Muestra la lista especializada con miniaturas gastronómicas, categorías,
/// estrellas de calificación, badges de estado, gestión de visibilidad y botón de nuevo restaurante.
class AdminRestaurantsScreen extends StatelessWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminHomeScreen(initialTipo: TurismoTipo.restaurante);
  }
}
