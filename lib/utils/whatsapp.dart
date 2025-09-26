// lib/utils/whatsapp.dart
import 'package:url_launcher/url_launcher.dart';

const _miNumeroE164 = '+5493704787285';

/// Abre WhatsApp hacia tu número con un mensaje opcional.
/// Usa enlace universal (wa.me). Si no hay WhatsApp, abre el navegador.
Future<void> contactarPorWhatsApp([String message = 'Hola! Vi la app Cotizador Dólar 👋']) async {
  final digits = _miNumeroE164.replaceAll('+', '');
  final uri = Uri.parse(
    'https://wa.me/$digits${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Si querés un helper genérico para otros números:
Future<void> abrirWhatsApp({
  required String phoneE164,
  String message = '',
}) async {
  final digits = phoneE164.replaceAll('+', '');
  final uri = Uri.parse(
    'https://wa.me/$digits${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
