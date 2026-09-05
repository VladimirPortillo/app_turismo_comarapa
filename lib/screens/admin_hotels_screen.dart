import 'package:flutter/material.dart';

import '../models/turismo_tipo.dart';
import 'admin_home_screen.dart';

/// Pantalla dedicada para Administrar Hoteles en el Panel de Administración.
/// Muestra la interfaz especializada con rangos de precios en Bolivianos (Bs min–max),
/// calificación por estrellas, badges de estado, gestión de visibilidad y formulario de nuevo hotel.
class AdminHotelsScreen extends StatelessWidget {
  const AdminHotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminHomeScreen(initialTipo: TurismoTipo.hotel);
  }
}
