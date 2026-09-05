import 'package:flutter/material.dart';

import '../models/turismo_tipo.dart';
import 'admin_home_screen.dart';

/// Pantalla dedicada para Administrar Eventos en el Panel de Administración.
/// Muestra la interfaz especializada con tarjetas de fecha (día y mes),
/// periodicidad anual/única, badges de estado, gestión de visibilidad y formulario de nuevo evento.
class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminHomeScreen(initialTipo: TurismoTipo.evento);
  }
}
