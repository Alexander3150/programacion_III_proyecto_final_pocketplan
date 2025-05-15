import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/pages/datos_ahorro_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_ahorro.dart';
import 'package:intl/intl.dart';

// Colores personalizados
class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF81C784);
  static const Color background = Color(0xFFE8F5E9);
  static const Color textDark = Color(0xFF1B5E20);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF4CAF50);
  static const Color textField = Colors.white;
}

// Lista global temporal
List<SimuladorAhorro> simuladoresGuardados = [];

class GuardarSimuladorDeAhorrosPage extends StatelessWidget {
  const GuardarSimuladorDeAhorrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Simuladores Guardados',
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
      body: const _GuardarSimuladorDeAhorrosWidget(),
    );
  }
}

class _GuardarSimuladorDeAhorrosWidget extends StatefulWidget {
  const _GuardarSimuladorDeAhorrosWidget();

  @override
  State<_GuardarSimuladorDeAhorrosWidget> createState() =>
      _GuardarSimuladorDeAhorrosWidgetState();
}

class _GuardarSimuladorDeAhorrosWidgetState
    extends State<_GuardarSimuladorDeAhorrosWidget> {
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  double calcularProgreso(SimuladorAhorro simulador) {
    double montoRestante = simulador.monto - simulador.montoInicial;
    if (montoRestante < 0) montoRestante = 0;
    if (simulador.monto == 0) return 0.0;
    return (simulador.monto - montoRestante) / simulador.monto;
  }

  Color _getProgressColor(double progreso) {
    final porcentaje = progreso * 100;

    if (porcentaje <= 25) {
      return Colors.red;
    } else if (porcentaje <= 50) {
      return Colors.yellow;
    } else if (porcentaje <= 75) {
      return Colors.cyan;
    } else {
      return Colors.green;
    }
  }

  void _eliminarSimulador(int index) async {
    bool confirm = await _mostrarConfirmacionEliminar();
    if (confirm) {
      setState(() {
        simuladoresGuardados.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Simulador eliminado!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool> _mostrarConfirmacionEliminar() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmación de eliminación'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este simulador?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _editarSimulador(int index) async {
    final actualizado = await Navigator.pushNamed(
      context,
      '/editar_simulador',
      arguments: {'index': index, 'simulador': simuladoresGuardados[index]},
    );

    if (actualizado == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Simulador actualizado!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _verDatosSimulador(int index) async {
    final simulador = simuladoresGuardados[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatosAhorroPage(simulador: simulador),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          simuladoresGuardados.isEmpty
              ? const Center(
                child: Text(
                  'No hay simuladores guardados.',
                  style: TextStyle(color: AppColors.textDark, fontSize: 18),
                ),
              )
              : ListView.builder(
                itemCount: simuladoresGuardados.length,
                itemBuilder: (context, index) {
                  final simulador = simuladoresGuardados[index];
                  final progreso = calcularProgreso(simulador);
                  final progressColor = _getProgressColor(progreso);

                  return Card(
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfo(
                            'Objetivo del Ahorro:',
                            simulador.objetivo,
                          ),
                          _buildInfo('Periodo a Ahorrar:', simulador.periodo),
                          _buildInfo(
                            'Monto a Ahorrar:',
                            'Q${simulador.monto.toStringAsFixed(2)}',
                          ),
                          _buildInfo(
                            'Monto Inicial:',
                            'Q${simulador.montoInicial.toStringAsFixed(2)}',
                          ),
                          _buildInfo(
                            'Fecha de Inicio:',
                            _formatDate(simulador.fechaInicio),
                          ),
                          _buildInfo(
                            'Fecha de Fin:',
                            _formatDate(simulador.fechaFin),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Progreso del Ahorro:',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progressColor,
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Progreso: ${(progreso * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_red_eye,
                                  color: AppColors.textDark,
                                ),
                                tooltip: 'Ver detalles',
                                onPressed: () => _verDatosSimulador(index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.textDark,
                                ),
                                onPressed: () => _editarSimulador(index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.textDark,
                                ),
                                onPressed: () => _eliminarSimulador(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 16,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


