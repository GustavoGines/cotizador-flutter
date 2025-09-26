import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/whatsapp.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  final String appVersion;
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actionsExtra; // extras por pantalla
  final bool scrollBody; // 👈 NUEVO: controla el scroll del body

  const AppShell({
    super.key,
    required this.child,
    required this.isDark,
    required this.onThemeChanged,
    required this.appVersion,
    this.floatingActionButton,
    this.actionsExtra,
    this.scrollBody = true, // por defecto como antes (con scroll)
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final contentCard = Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child, // contenido específico de cada pantalla
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text("Cotizador Dólar API"),
        centerTitle: true,
        actions: [
          // Badge de versión
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white70),
                color: Colors.white.withOpacity(0.08),
              ),
              child: Text(
                'v$appVersion',
                style: const TextStyle(
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          // Acerca de (con WhatsApp)
          IconButton(
            tooltip: 'Acerca de',
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Cotizador Dólar API',
                applicationVersion: appVersion,
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.apps, size: 48),
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'App para consultar cotizaciones y promedios históricos.',
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                    label: const Text('Escribirme por WhatsApp'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      contactarPorWhatsApp(
                        'Hola Gustavo! 👋 Te escribo desde la app Cotizador Dólar.',
                      );
                    },
                  ),
                ],
              );
            },
          ),

          // Tema
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: Colors.white,
          ),
          Switch(
            value: isDark,
            onChanged: onThemeChanged,
            activeThumbColor: Colors.white,
          ),

          // Acciones extra (opcionales)
          ...?actionsExtra,
        ],
      ),

      body: Center(
        child: scrollBody
            ? SingleChildScrollView(child: contentCard) // con scroll (default)
            : contentCard, // sin scroll
      ),

      floatingActionButton: floatingActionButton,
    );
  }
}
