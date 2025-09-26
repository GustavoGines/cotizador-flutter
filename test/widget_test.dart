// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cotizador_dolar_api/main.dart';

void main() {
  testWidgets('Smoke test: renderiza título y versión', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      analytics: null,    // no mockeamos Analytics acá
      appVersion: 'test', // versión fija de prueba
    ));

    // Esperar animaciones iniciales (FadeTransition, etc.)
    await tester.pumpAndSettle();

    // Título de la app
    expect(find.text('Cotizador Dólar API'), findsWidgets);

    // Badge con la versión: "v" + appVersion
    expect(find.text('vtest'), findsOneWidget);
  });
}
