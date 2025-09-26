import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/app_shell.dart';
import '../services/promedios_service.dart';

class PromediosScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  final String appVersion;

  const PromediosScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.appVersion,
  });

  @override
  State<PromediosScreen> createState() => _PromediosScreenState();
}

class _PromediosScreenState extends State<PromediosScreen> {
  // Filtros
  String _tipo = 'blue';
  final String _tipoValor = 'venta';
  int? _anio; // null => Todos
  int? _mes;  // null => Todos

  // Paginación por año (solo si _anio == null && _mes == null)
  int _yearPageIndex = 0;
  List<int> _yearsPages = [];

  // Gráfico: true=barras, false=línea
  bool _barChart = true;

  // Tamaño / modo compacto
  final bool _compactCharts = true;
  double get _chartHeight => 160; // compacto

  late Future<List<Promedio>> _future;

  // ScrollControllers para la tabla
  final _tableVController = ScrollController();
  final _tableHController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _tableVController.dispose();
    _tableHController.dispose();
    super.dispose();
  }

  Future<List<Promedio>> _load() async {
    final data = await PromediosService.fetchPromedios(
      tipo: _tipo,
      tipoValor: _tipoValor,
      anio: _anio,
      mes: _mes,
    );

    // Si es "Todos/Todos" preparo la paginación por año
    if (_anio == null && _mes == null) {
      final yearsSet = <int>{};
      for (final p in data) {
        yearsSet.add(p.anio);
      }
      final list = yearsSet.toList()..sort((a, b) => b.compareTo(a)); // desc
      _yearsPages = list;
      if (_yearPageIndex >= _yearsPages.length) {
        _yearPageIndex = 0;
      }
    } else {
      _yearsPages = [];
      _yearPageIndex = 0;
    }

    return data;
  }

  // Helpers
  String _mesEnTexto(int mes) {
    final date = DateTime(DateTime.now().year, mes, 1);
    return toBeginningOfSentenceCase(DateFormat.MMMM('es_AR').format(date)) ?? '';
  }

  List<int> _years() {
    final current = DateTime.now().year;
    const base = 2018;
    return List.generate(current - base + 1, (i) => base + i).reversed.toList();
  }

  List<int> _months() => List.generate(12, (i) => i + 1);

  // Handlers
  void _onTipoChanged(String value) {
    setState(() {
      _tipo = value;
      _yearPageIndex = 0;
      _future = _load();
    });
  }

  void _onAnioChanged(int? value) {
    setState(() {
      _anio = value; // puede ser null (Todos)
      if (_anio == null) _mes = null; // si año = Todos, mes también
      _yearPageIndex = 0;
      _future = _load();
    });
  }

  void _onMesChanged(int? value) {
    if (_anio == null) return; // mes solo tiene sentido si hay año
    setState(() {
      _mes = value; // puede ser null (Todos)
      _yearPageIndex = 0;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat("#,##0.00", "es_AR");

    // Altura para ver ~4 filas cómodas
    const double tableHeight = 260.0;

    return AppShell(
      isDark: widget.isDark,
      onThemeChanged: widget.onThemeChanged,
      appVersion: widget.appVersion,
      scrollBody: false, // scrolleamos nosotros con ListView
      child: FutureBuilder<List<Promedio>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("⚠️ ${snapshot.error}"));
          }

          final allData = snapshot.data ?? [];

          // Dataset visible (tabla + gráfico)
          List<Promedio> visibleData;
          String titleInfo = '';

          if (_anio == null && _mes == null) {
            // --- MODO PAGINADO POR AÑO ---
            if (_yearsPages.isEmpty) {
              return const Center(child: Text("No hay años disponibles"));
            }
            final currentYear = _yearsPages[_yearPageIndex];
            titleInfo = "Año $currentYear — 12 meses";
            visibleData = allData.where((p) => p.anio == currentYear).toList()
              ..sort((a, b) => a.mes.compareTo(b.mes));
          } else {
            // --- SIN PAGINACIÓN (filtros específicos) ---
            visibleData = List.of(allData);
            if (_anio != null) {
              visibleData = visibleData.where((p) => p.anio == _anio).toList();
            }
            if (_mes != null) {
              visibleData = visibleData.where((p) => p.mes == _mes).toList();
            }
            visibleData.sort((a, b) {
              final byYear = a.anio.compareTo(b.anio);
              if (byYear != 0) return byYear;
              return a.mes.compareTo(b.mes);
            });

            titleInfo = _anio == null
                ? "Todos los años"
                : (_mes == null
                    ? "Año $_anio — todos los meses"
                    : "Año $_anio — mes ${_mesEnTexto(_mes!)} ($_mes)");
          }

          // Calculamos densidad de etiquetas para el eje X (evita solapamiento)
          final int labelStep = ((visibleData.length) / (_compactCharts ? 8 : 10))
              .ceil()
              .clamp(1, 12);

          // ✅ Un único scroll vertical
          return ListView(
            children: [
              // Filtros
              Card(
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Tipo
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          value: _tipo,
                          decoration: const InputDecoration(
                            labelText: "Tipo de dólar",
                          ),
                          items: const [
                            DropdownMenuItem(value: 'oficial', child: Text('Oficial')),
                            DropdownMenuItem(value: 'blue', child: Text('Blue')),
                            DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                            DropdownMenuItem(value: 'mep', child: Text('MEP')),
                            DropdownMenuItem(value: 'ccl', child: Text('CCL')),
                          ],
                          onChanged: (v) => _onTipoChanged(v!),
                        ),
                      ),

                      // Año + Mes lado a lado sin overflow
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 8.0; // separación entre selects
                          final half = (constraints.maxWidth - gap) / 2;

                          return Row(
                            children: [
                              SizedBox(
                                width: half,
                                child: DropdownButtonFormField<int?>(
                                  isDense: true,
                                  isExpanded: true,
                                  value: _anio,
                                  decoration: const InputDecoration(
                                    labelText: "Año",
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text("Todos")),
                                    ..._years().map((y) => DropdownMenuItem<int?>(value: y, child: Text("$y"))),
                                  ],
                                  onChanged: _onAnioChanged,
                                ),
                              ),
                              const SizedBox(width: gap),
                              SizedBox(
                                width: half,
                                child: DropdownButtonFormField<int?>(
                                  isDense: true,
                                  isExpanded: true,
                                  value: _mes,
                                  decoration: const InputDecoration(
                                    labelText: "Mes",
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text("Todos")),
                                    ..._months().map(
                                      (m) => DropdownMenuItem<int?>(value: m, child: Text("${_mesEnTexto(m)} ($m)")),
                                    ),
                                  ],
                                  onChanged: (_anio == null) ? null : _onMesChanged,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Toggle gráfico
                      SizedBox(
                        width: 220,
                        child: Row(
                          children: [
                            const Text("Gráfico:"),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: true, label: Text("Barras")),
                                  ButtonSegment(value: false, label: Text("Línea")),
                                ],
                                selected: {_barChart},
                                onSelectionChanged: (s) => setState(() => _barChart = s.first),
                                showSelectedIcon: false, // no muestra check (ahorra ancho)
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Encabezado + paginación (si aplica)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(titleInfo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_anio == null && _mes == null && _yearsPages.isNotEmpty)
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Anterior",
                            onPressed: _yearPageIndex > 0 ? () => setState(() => _yearPageIndex--) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text("${_yearPageIndex + 1}/${_yearsPages.length}"),
                          IconButton(
                            tooltip: "Siguiente",
                            onPressed: (_yearPageIndex < _yearsPages.length - 1)
                                ? () => setState(() => _yearPageIndex++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // TABLA (altura fija + scroll interno con controllers)
              SizedBox(
                height: tableHeight,
                child: Scrollbar(
                  controller: _tableVController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _tableVController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _tableHController,
                      thumbVisibility: false,
                      notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: _tableHController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text("Año")),
                            DataColumn(label: Text("Mes")),
                            DataColumn(label: Text("Prom. (ARS)")),
                          ],
                          rows: visibleData.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.anio.toString())),
                                DataCell(Text(_mesEnTexto(p.mes))),
                                DataCell(Text(
                                  currency.format(p.promedio),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // GRÁFICO (compacto) — debajo de la tabla
              SizedBox(
                height: _chartHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenW = constraints.maxWidth;
                    final perPoint = _compactCharts ? 28.0 : 36.0;
                    final contentW = (visibleData.length * perPoint).toDouble();
                    final chartWidth = contentW < screenW ? screenW : contentW;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: chartWidth, maxWidth: chartWidth),
                        child: _barChart
                            ? _BarChartPromedios(
                                data: visibleData,
                                monthName: _mesEnTexto,
                                labelStep: labelStep, // 👈 espaciado de etiquetas
                              )
                            : _LineChartPromedios(
                                data: visibleData,
                                monthName: _mesEnTexto,
                                labelStep: labelStep, // 👈 espaciado de etiquetas
                              ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
              Text(
                "Desarrollado por Gustavo Ginés\nUTN – FRRe – TUP",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---- Widgets de gráficos ----
class _BarChartPromedios extends StatelessWidget {
  final List<Promedio> data;
  final String Function(int) monthName;
  final int labelStep;

  const _BarChartPromedios({
    required this.data,
    required this.monthName,
    this.labelStep = 1,
  });

  String _abbrMes(int m) {
    const abbr = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return (m >= 1 && m <= 12) ? abbr[m-1] : '$m';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(data)
      ..sort((a, b) {
        final byYear = a.anio.compareTo(b.anio);
        if (byYear != 0) return byYear;
        return a.mes.compareTo(b.mes);
      });

    final groups = <BarChartGroupData>[
      for (int i = 0; i < sorted.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: sorted[i].promedio, width: 10)],
          barsSpace: 3,
        ),
    ];

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28, // 1 línea
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                if (idx % labelStep != 0) return const SizedBox.shrink();

                final p = sorted[idx];
                final yy = (p.anio % 100).toString().padLeft(2, '0');
                final label = '${_abbrMes(p.mes)}-$yy'; // p.ej. Ene-25
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }
}

class _LineChartPromedios extends StatelessWidget {
  final List<Promedio> data;
  final String Function(int) monthName;
  final int labelStep;

  const _LineChartPromedios({
    required this.data,
    required this.monthName,
    this.labelStep = 1,
  });

  String _abbrMes(int m) {
    const abbr = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return (m >= 1 && m <= 12) ? abbr[m-1] : '$m';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(data)
      ..sort((a, b) {
        final byYear = a.anio.compareTo(b.anio);
        if (byYear != 0) return byYear;
        return a.mes.compareTo(b.mes);
      });

    final spots = <FlSpot>[
      for (int i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].promedio),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28, // 1 línea
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                if (idx % labelStep != 0) return const SizedBox.shrink();

                final p = sorted[idx];
                final yy = (p.anio % 100).toString().padLeft(2, '0');
                final label = '${_abbrMes(p.mes)}-$yy';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
