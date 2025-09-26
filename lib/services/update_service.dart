import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  /// Cambiá por tu endpoint (Render o Firebase Storage latest.json)
  static const String apiUrl =
      "https://cotizador-dolar-api.onrender.com/api/version";

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // 1) versión actual de la app (name: 1.0.6, code: buildNumber)
      final info = await PackageInfo.fromPlatform();
      final current = _normalizeVersion(info.version);

      // 2) consulta al backend con timeout
      final resp = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final latest = _normalizeVersion(data["version"] ?? "0.0.0");
      final minV = _normalizeVersion(data["min_version"] ?? "0.0.0");
      final urlStr = (data["url"] as String? ?? "").trim();

      // 3) tras async gap: verificar que el widget siga montado
      if (!context.mounted) return;

      // 4) decidir: obligatoria u opcional
      if (_compareVersions(current, minV) < 0) {
        _showDialog(
          context,
          obligatorio: true,
          url: urlStr,
          notes: data['notes'] as String?,
        );
      } else if (_compareVersions(current, latest) < 0) {
        _showDialog(
          context,
          obligatorio: false,
          url: urlStr,
          notes: data['notes'] as String?,
        );
      }
    } catch (e) {
      debugPrint("Error al verificar actualización: $e");
    }
  }

  // "1.2.0+5" -> "1.2.0"
  static String _normalizeVersion(String v) => v.split('+').first.trim();

  // compara A vs B: 1 si A>B; -1 si A<B; 0 si ==
  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (pa.length < 3) {
      pa.add(0);
    }
    while (pb.length < 3) {
      pb.add(0);
    }
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i] ? 1 : -1;
    }
    return 0;
  }

  static void _showDialog(
    BuildContext context, {
    required bool obligatorio,
    required String url,
    String? notes,
  }) {
    // validar URL mínima
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme("http") && !uri.isScheme("https"))) {
      debugPrint("URL de actualización inválida: $url");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !obligatorio,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva versión disponible"),
        content: Text(
          notes?.trim().isNotEmpty == true
              ? notes!.trim()
              : obligatorio
              ? "Debes actualizar para seguir usando la app."
              : "Hay una actualización disponible. ¿Querés instalarla ahora?",
        ),
        actions: [
          if (!obligatorio)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Más tarde"),
            ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Abrir en navegador externo (más compatible)
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!ok) {
                // fallback
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }
}
