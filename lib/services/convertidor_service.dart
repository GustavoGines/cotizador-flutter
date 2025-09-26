import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado del endpoint /api/convertir
class ConversionResult {
  final double cotizacion;
  final double resultado;

  const ConversionResult({required this.cotizacion, required this.resultado});
}

/// Lógica de red + normalización de monto
class ConvertidorService {
  static const String _base = 'https://cotizador-dolar-api.onrender.com/api';

  /// Normaliza entrada: admite "1.234,56", "1234,56", "1234.56"
  static String normalizeAmount(String raw) {
    var s = raw.trim();
    s = s.replaceAll(' ', '').replaceAll('.', ''); // quita miles
    s = s.replaceAll(',', '.'); // coma -> punto
    final match = RegExp(r'^\d*\.?\d{0,}$').stringMatch(s);
    return match ?? '';
  }

  /// Llama al backend y devuelve ConversionResult
  static Future<ConversionResult> convertir({
    required String valorRaw,
    required String tipo, // oficial|blue|mep|ccl|tarjeta
    required String direccion, // usd_a_pesos|pesos_a_usd
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final valor = normalizeAmount(valorRaw);
    if (valor.isEmpty) {
      throw ArgumentError('Valor vacío o inválido');
    }

    final uri = Uri.parse(
      '$_base/convertir?valor=$valor&tipo=$tipo&direccion=$direccion',
    );

    final resp = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(timeout);

    if (resp.statusCode != 200) {
      throw HttpException('Error ${resp.statusCode} en servidor');
    }

    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final cot = (map['cotizacion'] as num).toDouble();
    final res = (map['resultado'] as num).toDouble();

    return ConversionResult(cotizacion: cot, resultado: res);
  }
}

/// Excepción HTTP simple
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
