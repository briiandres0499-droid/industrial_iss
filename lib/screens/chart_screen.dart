import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../database/database_helper.dart';
import '../models/measurement.dart';
import '../utils/constants.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Measurement>> _futureMediciones;
  String _variableSeleccionada = AppConstants.variables.first;

  @override
  void initState() {
    super.initState();
    _futureMediciones = _dbHelper.getAllMeasurements();
  }

  Map<String, int> _contarPorVariable(List<Measurement> mediciones) {
    final Map<String, int> conteo = {
      for (var v in AppConstants.variables) v: 0,
    };
    for (final m in mediciones) {
      conteo[m.variable] = (conteo[m.variable] ?? 0) + 1;
    }
    return conteo;
  }

  List<Measurement> _filtrarPorVariable(
      List<Measurement> mediciones, String variable) {
    final filtradas = mediciones.where((m) => m.variable == variable).toList();
    // Se ordenan del más antiguo al más reciente para que la línea avance en el tiempo.
    filtradas.sort((a, b) {
      final claveA = '${a.fecha} ${a.hora}';
      final claveB = '${b.fecha} ${b.hora}';
      return claveA.compareTo(claveB);
    });
    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfica de Variables'),
      ),
      body: FutureBuilder<List<Measurement>>(
        future: _futureMediciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay datos suficientes para graficar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final mediciones = snapshot.data!;
          final conteoPorVariable = _contarPorVariable(mediciones);
          final medicionesFiltradas =
              _filtrarPorVariable(mediciones, _variableSeleccionada);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registros por variable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.azulOscuro,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 240,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (conteoPorVariable.values.isEmpty
                                      ? 1
                                      : conteoPorVariable.values
                                          .reduce((a, b) => a > b ? a : b))
                                  .toDouble() +
                              1,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 28),
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
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= AppConstants.variables.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        AppConstants.variables[index],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(
                              show: true, drawVerticalLine: false),
                          barGroups: List.generate(
                              AppConstants.variables.length, (index) {
                            final variable = AppConstants.variables[index];
                            final cantidad = conteoPorVariable[variable] ?? 0;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: cantidad.toDouble(),
                                  color: AppTheme.azulMedio,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Evolución del valor en el tiempo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.azulOscuro,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _variableSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Variable',
                    prefixIcon: Icon(Icons.tune),
                  ),
                  items: AppConstants.variables.map((String variable) {
                    return DropdownMenuItem<String>(
                      value: variable,
                      child: Text(variable),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() {
                      _variableSeleccionada = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 240,
                      child: medicionesFiltradas.isEmpty
                          ? Center(
                              child: Text(
                                'No hay registros de $_variableSeleccionada todavía',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true, reservedSize: 40),
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
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >=
                                                medicionesFiltradas.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            '#${index + 1}',
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                gridData: const FlGridData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    isCurved: true,
                                    color: AppTheme.azulOscuro,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    spots: List.generate(
                                        medicionesFiltradas.length, (index) {
                                      return FlSpot(
                                        index.toDouble(),
                                        medicionesFiltradas[index].valor,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (medicionesFiltradas.isNotEmpty)
                  Text(
                    'Unidad: ${medicionesFiltradas.last.unidad}  ·  ${medicionesFiltradas.length} registro(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
