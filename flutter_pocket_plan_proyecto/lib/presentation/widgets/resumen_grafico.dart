import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ResumenGrafico extends StatelessWidget {
  final Map<String, double> distribucion;
  final Color Function(String etiqueta) obtenerColorPorEtiqueta;

  const ResumenGrafico({
    super.key,
    required this.distribucion,
    required this.obtenerColorPorEtiqueta,
  });

  @override
  Widget build(BuildContext context) {
    final sections =
        distribucion.entries.map((entry) {
          final color = obtenerColorPorEtiqueta(entry.key);
          return PieChartSectionData(
            value: entry.value,
            title: '${entry.value.toStringAsFixed(1)}%',
            color: color,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: sections,
          ),
        ),
      ),
    );
  }
}
