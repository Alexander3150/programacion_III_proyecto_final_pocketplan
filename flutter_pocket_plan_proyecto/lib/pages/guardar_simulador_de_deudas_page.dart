import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pocket_plan_proyecto/pages/datos_deuda_page.dart';
import 'package:flutter_pocket_plan_proyecto/pages/editar_simulador_de_deudas_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_deuda.dart';

// Definición de colores personalizados
class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF81C784);
  static const Color background = Color(0xFFE8F5E9);
  static const Color textDark = Color(0xFF1B5E20);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF4CAF50);
}

List<SimuladorDeuda> simuladoresDeudaGuardados = [];

class GuardarSimuladorDeDeudasPage extends StatefulWidget {
  const GuardarSimuladorDeDeudasPage({super.key});

  @override
  State<GuardarSimuladorDeDeudasPage> createState() => _GuardarSimuladorDeDeudasPageState();
}

class _GuardarSimuladorDeDeudasPageState extends State<GuardarSimuladorDeDeudasPage> {
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  double calcularProgreso(SimuladorDeuda simulador) {
    double restante = simulador.monto - simulador.montoCancelado;
    if (restante < 0) restante = 0;
    if (simulador.monto == 0) return 0.0;
    return (simulador.monto - restante) / simulador.monto;
  }

  Color _getProgressColor(double progreso) {
    final porcentaje = progreso * 100;
    if (porcentaje <= 25) return AppColors.error;
    if (porcentaje <= 50) return AppColors.warning;
    if (porcentaje <= 75) return Colors.amber;
    return AppColors.success;
  }

  String _getProgressStatus(double progreso) {
    final porcentaje = progreso * 100;
    if (porcentaje <= 25) return 'Iniciado';
    if (porcentaje <= 50) return 'En progreso';
    if (porcentaje <= 75) return 'Avanzado';
    return porcentaje < 100 ? 'Casi completado' : 'Completado';
  }

  void _eliminarSimulador(int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deuda', style: TextStyle(color: AppColors.textDark)),
        content: const Text('¿Está seguro que desea eliminar esta deuda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        simuladoresDeudaGuardados.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deuda eliminada.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _verDatosSimulador(int index) async {
    final simulador = simuladoresDeudaGuardados[index];
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DatosDeudaPage(simulador: simulador)),
    );
    setState(() {}); // Recargar la pantalla por si hubo cambios
  }

  void _editarSimulador(int index) async {
    final simulador = simuladoresDeudaGuardados[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarSimuladorDeDeudasPage(
          simulador: simulador,
          index: index,
        ),
      ),
    );
    setState(() {}); // Recargar la pantalla por si hubo cambios
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas Registradas', style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.primary,
        elevation: 4,
        iconTheme: const IconThemeData(color: AppColors.textLight),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: simuladoresDeudaGuardados.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 60, color: AppColors.accent.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No hay deudas registradas',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textDark.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega una deuda desde el simulador',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: simuladoresDeudaGuardados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final simulador = simuladoresDeudaGuardados[index];
                  final progreso = calcularProgreso(simulador);
                  final color = _getProgressColor(progreso);
                  final status = _getProgressStatus(progreso);

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  simulador.motivo,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  simulador.periodo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Monto Total:', 'Q${simulador.monto.toStringAsFixed(2)}'),
                          _buildInfoRow('Monto ya Cancelado:', 'Q${simulador.montoCancelado.toStringAsFixed(2)}'),
                          _buildInfoRow('Fecha Inicio:', _formatDate(simulador.fechaInicio)),
                          _buildInfoRow('Fecha Fin:', _formatDate(simulador.fechaFin)),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progreso: ${(progreso * 100).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: progreso,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 22),
                                color: AppColors.primary,
                                tooltip: 'Ver detalles',
                                onPressed: () => _verDatosSimulador(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 22),
                                color: AppColors.warning,
                                tooltip: 'Editar',
                                onPressed: () => _editarSimulador(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 22),
                                color: AppColors.error,
                                tooltip: 'Eliminar',
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}