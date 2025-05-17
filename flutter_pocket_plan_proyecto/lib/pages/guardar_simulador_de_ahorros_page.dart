import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/pages/datos_ahorro_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_ahorro.dart';
import 'package:flutter_pocket_plan_proyecto/pages/simulador_de_ahorros_page.dart';
import 'package:intl/intl.dart';


// Colores personalizados  
class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color secondary = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5FBF5);
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF263238);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);
  static const Color shadow = Color(0x1A000000);
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
    bool confirm = await _mostrarConfirmacionEliminar();
    if (confirm) {
      setState(() {
        final eliminado = simuladoresGuardados.removeAt(index);
        
        // Mostrar snackbar con opción de deshacer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Simulador eliminado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DESHACER',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  simuladoresGuardados.insert(index, eliminado);
                });
              },
            ),
          ),
        );
      });
    }
  }

      Future<bool> _mostrarConfirmacionEliminar() async {
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar simulador', 
          style: TextStyle(color: AppColors.textDark)),
      content: const Text('¿Estás seguro de que deseas eliminar este simulador?'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar',
            style: TextStyle(color: AppColors.textDark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Eliminar',
            style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  ) ?? false;
}

  void _editarSimulador(int index) async {
    final actualizado = await Navigator.pushNamed(
      context,
      '/editar_simulador',
      arguments: {'index': index, 'simulador': simuladoresGuardados[index]},
    );

    if (actualizado == true) {
      setState(() {});
      _mostrarMensajeEmergente('¡Simulador actualizado!', AppColors.success);
    }
  }

  void _verDatosSimulador(int index) async {
    final simulador = simuladoresGuardados[index];
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          DatosAhorroPage(simulador: simulador),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
    setState(() {});
  }

  void _mostrarMensajeEmergente(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: simuladoresGuardados.isEmpty
            ? _buildEmptyState()
            : _buildListaSimuladores(),
      ),
    );
  }

  Widget _buildListaSimuladores() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: simuladoresGuardados.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final simulador = simuladoresGuardados[index];
        final progreso = calcularProgreso(simulador);
        final progressColor = _getProgressColor(progreso);
        final status = _getProgressStatus(progreso);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _verDatosSimulador(index),
            onLongPress: () => _editarSimulador(index),
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.shadow,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            simulador.objetivo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            simulador.periodo,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Monto a ahorrar:', 'Q${simulador.monto.toStringAsFixed(2)}'),
                    _buildInfoRow('Monto inicial:', 'Q${simulador.montoInicial.toStringAsFixed(2)}'),
                    _buildInfoRow('Fecha inicio:', _formatDate(simulador.fechaInicio)),
                    _buildInfoRow('Fecha fin:', _formatDate(simulador.fechaFin)),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso: ${(progreso * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: progressColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.warning,
                          tooltip: 'Editar',
                          onPressed: () => _editarSimulador(index),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarSimulador(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 80,
            color: AppColors.primaryLight.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay simuladores guardados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Crea un simulador de ahorro para comenzar a gestionar tus metas financieras',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SimuladorAhorrosScreen()),
            );
          },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 2,
            ),
            child: const Text('Crear simulador de ahorro'),
          ),
        ],
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
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}