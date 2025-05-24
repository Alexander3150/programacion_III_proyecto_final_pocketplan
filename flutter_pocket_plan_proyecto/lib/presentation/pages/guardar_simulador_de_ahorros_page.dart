import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/repositories/cuota_ahorro_repository.dart';
import '../../data/models/repositories/simulador_ahorro_repository.dart';
import '../../data/models/simulador_ahorro.dart';
import '../widgets/global_components.dart';
import '../providers/user_provider.dart';
import 'datos_ahorro_page.dart';
import 'editar_simulador_de_ahorros_page.dart';
import 'simulador_de_ahorros_page.dart';

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

class GuardarSimuladorDeAhorrosPage extends StatelessWidget {
  const GuardarSimuladorDeAhorrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false; // Previene el pop normal
      },
      child: GlobalLayout(
        titulo: 'Simuladores Guardados',
        mostrarDrawer: true,
        mostrarBotonHome: true,
        mostrarBotonInforme: true,
        tipoInforme: 'ahorro',
        navIndex: 0,
        body: const _GuardarSimuladorDeAhorrosWidget(),
      ),
    );
  }
}

// --- Modelo auxiliar para poder ordenar por progreso
class SimuladorAhorroConProgreso {
  final SimuladorAhorro simulador;
  final double progreso;

  SimuladorAhorroConProgreso(this.simulador, this.progreso);
}

class _GuardarSimuladorDeAhorrosWidget extends StatefulWidget {
  const _GuardarSimuladorDeAhorrosWidget();

  @override
  State<_GuardarSimuladorDeAhorrosWidget> createState() =>
      _GuardarSimuladorDeAhorrosWidgetState();
}

class _GuardarSimuladorDeAhorrosWidgetState
    extends State<_GuardarSimuladorDeAhorrosWidget> {
  final SimuladorAhorroRepository _repository = SimuladorAhorroRepository();
  final CuotaAhorroRepository _cuotaRepo = CuotaAhorroRepository();
  List<SimuladorAhorroConProgreso> simuladoresGuardados = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _loadSimuladores();
  }

  Future<void> _loadSimuladores() async {
    setState(() => _isLoading = true);

    if (_userId != null) {
      // 1. Obtén los simuladores normales
      final simuladores = await _repository.getSimuladoresAhorroByUser(
        _userId!,
      );

      // 2. Convierte a SimuladorAhorroConProgreso usando Future.wait para obtener los progresos
      final progresos = await Future.wait(
        simuladores.map((s) async {
          final double ahorrado = await _cuotaRepo.getTotalAhorradoPorSimulador(
            s.id!,
            _userId!,
          );
          final double progreso =
              s.monto == 0 ? 0.0 : ((ahorrado) / s.monto).clamp(0.0, 1.0);
          return SimuladorAhorroConProgreso(s, progreso);
        }),
      );

      // 3. Ordena los progresos antes de asignarlos
      progresos.sort((a, b) {
        if (a.progreso >= 1 && b.progreso < 1) return 1;
        if (a.progreso < 1 && b.progreso >= 1) return -1;
        return a.progreso.compareTo(b.progreso);
      });

      simuladoresGuardados = progresos; // <- ¡ESTE debe ser progresos!
    } else {
      simuladoresGuardados = [];
    }
    setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getProgressColor(double progreso) {
    final porcentaje = progreso * 100;
    if (porcentaje <= 25) return AppColors.error;
    if (porcentaje <= 50) return AppColors.warning;
    if (porcentaje <= 75) return const Color.fromARGB(255, 0, 195, 255);
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
      final SimuladorAhorroConProgreso eliminado = simuladoresGuardados[index];
      if (_userId != null) {
        await _repository.deleteSimuladorAhorro(
          eliminado.simulador.id!,
          _userId!,
        );
        await _loadSimuladores();
      }

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
        ),
      );
    }
  }

  Future<bool> _mostrarConfirmacionEliminar() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  'Eliminar simulador',
                  style: TextStyle(color: AppColors.textDark),
                ),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este simulador?',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _editarSimulador(SimuladorAhorro simulador) async {
    final actualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditarSimuladorDeAhorrosPage(simulador: simulador),
      ),
    );

    if (actualizado == true) {
      await _loadSimuladores();
      _mostrarMensajeEmergente('¡Simulador actualizado!', AppColors.success);
    }
  }

  void _verDatosSimulador(int index) async {
    final simulador = simuladoresGuardados[index].simulador;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                DatosAhorroPage(simulador: simulador),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
    await _loadSimuladores();
  }

  void _mostrarMensajeEmergente(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5FBF5), Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child:
                      simuladoresGuardados.isEmpty
                          ? _buildEmptyState()
                          : _buildListaSimuladores(),
                ),
      ),
    );
  }

  Widget _buildListaSimuladores() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: simuladoresGuardados.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final simuladorConProgreso = simuladoresGuardados[index];
        final simulador = simuladorConProgreso.simulador;
        final progreso = simuladorConProgreso.progreso;

        final progressColor = _getProgressColor(progreso);
        final status = _getProgressStatus(progreso);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _verDatosSimulador(index),
            onLongPress: () => _editarSimulador(simulador),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con ícono y objetivo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.savings,
                          size: 32,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            simulador.objetivo,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildPeriodoChip(simulador.periodo),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Info Rows
                    _buildInfoRow(
                      Icons.savings_outlined,
                      'Monto a ahorrar:',
                      'Q${simulador.monto.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      Icons.flag_outlined,
                      'Monto inicial:',
                      'Q${simulador.montoInicial.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      Icons.date_range_outlined,
                      'Fecha inicio:',
                      _formatDate(simulador.fechaInicio),
                    ),
                    _buildInfoRow(
                      Icons.event_outlined,
                      'Fecha fin:',
                      _formatDate(simulador.fechaFin),
                    ),
                    const SizedBox(height: 18),
                    // Progreso animado y status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Progreso: ${(progreso * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(status, progressColor),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progreso),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                                minHeight: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.warning,
                          tooltip: 'Editar',
                          onPressed: () => _editarSimulador(simulador),
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

  Widget _buildPeriodoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.33)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
      ),
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
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.16),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: color),
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
            size: 92,
            color: AppColors.primaryLight.withOpacity(0.26),
          ),
          const SizedBox(height: 32),
          Text(
            'No hay simuladores guardados',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark.withOpacity(0.77),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Text(
              'Crea un simulador de ahorro para comenzar a gestionar tus metas financieras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark.withOpacity(0.59),
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimuladorAhorrosScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: 3,
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Crear simulador'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.75)),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark.withOpacity(0.74),
                fontSize: 13.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
