import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final_360/screens/login_screen.dart';

// La validación ocurre antes de llamar a Supabase, así que estas pruebas
// no necesitan conexión ni inicializar el cliente.
void main() {
  Future<void> abrirLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.widgetWithText(ElevatedButton, 'Iniciar sesión');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
  }

  testWidgets('campos vacíos muestran mensajes de obligatorio', (tester) async {
    await abrirLogin(tester);
    await enviar(tester);

    expect(find.text('El correo electrónico es obligatorio.'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
  });

  testWidgets('correo con formato inválido es rechazado', (tester) async {
    await abrirLogin(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'correo-sin-arroba');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto123');
    await enviar(tester);

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
  });

  testWidgets('contraseña de menos de 6 caracteres es rechazada', (tester) async {
    await abrirLogin(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@comarapa.bo');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await enviar(tester);

    expect(
      find.text('La contraseña debe tener al menos 6 caracteres.'),
      findsOneWidget,
    );
  });
}
