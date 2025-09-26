import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../services/convertidor_service.dart';
import '../services/update_service.dart';
import '../widgets/app_shell.dart'; // 👈 usamos el layout compartido
import 'promedios_screen.dart';

class ConvertidorScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  final String appVersion;
  final FirebaseAnalytics? analytics;

  const ConvertidorScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.appVersion,
    this.analytics,
  });

  @override
  State<ConvertidorScreen> createState() => _ConvertidorScreenState();
}

class _ConvertidorScreenState extends State<ConvertidorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _valorController = TextEditingController();

  String _direccion = "usd_a_pesos";
  String _tipo = "oficial";
  String _resultado = "";
  String _cotizacion = "";

  Timer? _debounce;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );
    _logoController.forward();

    _valorController.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _valorController.removeListener(_onChanged);
    _valorController.dispose();
    _debounce?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _convertir);
  }

  Future<void> _convertir() async {
    final raw = _valorController.text;
    if (raw.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _resultado = '';
        _cotizacion = '';
      });
      return;
    }

    try {
      final r = await ConvertidorService.convertir(
        valorRaw: raw,
        tipo: _tipo,
        direccion: _direccion,
      );

      if (!mounted) return;
      setState(() {
        _cotizacion = NumberFormat("#,##0.00", "es_AR").format(r.cotizacion);
        _resultado = NumberFormat("#,##0.00", "es_AR").format(r.resultado);
      });

      await widget.analytics?.logEvent(
        name: 'conversion_ok',
        parameters: {
          'direccion': _direccion,
          'tipo': _tipo,
          'valor_entrada': ConvertidorService.normalizeAmount(raw),
          'app_version': widget.appVersion,
        },
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _resultado = "⏱️ Tiempo de espera agotado";
        _cotizacion = '';
      });
      await widget.analytics?.logEvent(name: 'conversion_timeout');
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() {
        _resultado = "❌ ${e.message}";
        _cotizacion = '';
      });
      await widget.analytics?.logEvent(name: 'conversion_server_error');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultado = "⚠️ Error de conexión";
        _cotizacion = '';
      });
      await widget.analytics?.logEvent(
        name: 'conversion_network_error',
        parameters: {'message': e.toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).textTheme.bodySmall?.color;
    final textMuted = baseColor?.withValues(alpha: 0.65);

    return AppShell(
      isDark: widget.isDark,
      onThemeChanged: widget.onThemeChanged,
      appVersion: widget.appVersion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Image.asset(
                'assets/icons/icon_utn.png',
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(height: 150),
              ),
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: _direccion,
            items: const [
              DropdownMenuItem(value: "usd_a_pesos", child: Text("USD → ARS")),
              DropdownMenuItem(value: "pesos_a_usd", child: Text("ARS → USD")),
            ],
            onChanged: (v) {
              setState(() => _direccion = v!);
              _onChanged();
            },
            decoration: const InputDecoration(labelText: "Conversión"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _valorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
            ],
            onChanged: (_) => _onChanged(),
            onSubmitted: (_) => _convertir(),
            decoration: InputDecoration(
              labelText: _direccion == "usd_a_pesos"
                  ? "Monto en USD"
                  : "Monto en ARS",
              prefixIcon: const Icon(Icons.attach_money),
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _tipo,
            items: const [
              DropdownMenuItem(value: 'oficial', child: Text('Oficial')),
              DropdownMenuItem(value: 'blue', child: Text('Blue')),
              DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
              DropdownMenuItem(value: 'mep', child: Text('MEP')),
              DropdownMenuItem(value: 'ccl', child: Text('CCL')),
            ],
            onChanged: (v) {
              setState(() => _tipo = v!);
              _onChanged();
            },
            decoration: const InputDecoration(
              labelText: "Tipo de Dólar",
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),

          const SizedBox(height: 20),

          if (_cotizacion.isNotEmpty)
            Text(
              "💵 Cotización ($_tipo): \$$_cotizacion ARS",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          if (_resultado.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Resultado: ${_direccion == "usd_a_pesos" ? '$_resultado ARS' : '$_resultado USD'}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text("Ver promedios históricos"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PromediosScreen(
                    isDark: widget.isDark,
                    onThemeChanged: widget.onThemeChanged,
                    appVersion: widget.appVersion,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          Text(
            "Desarrollado por Gustavo Ginés\nUTN – FRRe – TUP",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
        ],
      ),
    );
  }
}
