// lib/services/promedios_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class Promedio {
  final int anio;
  final int mes;
  final double promedio;

  Promedio({required this.anio, required this.mes, required this.promedio});

  factory Promedio.fromDynamic(Map<String, dynamic> json) {
    final y = json['anio'];
    final m = json['mes'];
    final p = json['promedio'];
    if (y == null || m == null || p == null) {
      throw const FormatException('Campos faltantes (anio/mes/promedio)');
    }
    int toInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : int.parse(v.toString()));
    double toDouble(dynamic v) => v is double
        ? v
        : (v is num
              ? v.toDouble()
              : double.parse(v.toString().replaceAll(',', '.')));

    return Promedio(anio: toInt(y), mes: toInt(m), promedio: toDouble(p));
  }
}

class PromediosService {
  static const String baseUrl =
      'https://cotizador-dolar-api.onrender.com/api/cotizaciones/promedio-mensual';

  static Future<List<Promedio>> fetchPromedios({
    String tipo = 'oficial',
    String tipoValor = 'venta',
    int? anio,
    int? mes,
  }) async {
    // 👇 clave: pedimos SIEMPRE flat=1 para recibir lista plana {anio, mes, promedio}
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'tipo': tipo,
        'tipo_valor': tipoValor,
        'flat': '1',
        if (anio != null) 'anio': anio.toString(),
        if (mes != null) 'mes': mes.toString(),
      },
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw HttpException('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
      }

      final decoded = json.decode(resp.body);
      final listDyn = (decoded is Map<String, dynamic>)
          ? decoded['resultados']
          : (decoded is List ? decoded : null);

      if (listDyn is! List) {
        throw const FormatException('Respuesta inválida del servidor');
      }

      return listDyn
          .map<Promedio>((e) => Promedio.fromDynamic(e as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('⏱️ Tiempo de espera agotado');
    } on SocketException {
      throw Exception('Sin conexión a Internet');
    } on HttpException catch (e) {
      throw Exception('Error de servidor: ${e.message}');
    } on FormatException {
      throw Exception('Respuesta inválida del servidor');
    } catch (e) {
      throw Exception('Error al cargar promedios: $e');
    }
  }
}
