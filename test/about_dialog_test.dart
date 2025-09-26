// test/about_dialog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cotizador_dolar_api/main.dart';

void main() {
  testWidgets('About muestra versión', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      analytics: null,
      appVersion: 'test',
    ));
    await tester.pumpAndSettle();

    // Toca el ícono de "info"
    final aboutBtn = find.byIcon(Icons.info_outline);
    expect(aboutBtn, findsOneWidget);
    await tester.tap(aboutBtn);
    await tester.pumpAndSettle();

    // Verifica que aparezca la versión y el nombre de la app
    expect(find.text('test'), findsWidgets);                 // versión en el diálogo
    expect(find.text('Cotizador Dólar API'), findsWidgets);  // título en AppBar y diálogo
  });
}
