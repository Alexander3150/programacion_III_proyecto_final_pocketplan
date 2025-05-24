import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/simulador_deuda_repository.dart';
import '../../data/models/simulador_deuda.dart';
import '../widgets/global_components.dart';
import '../providers/user_provider.dart';
import 'package:intl/intl.dart';

import 'datos_deuda_page.dart';
import 'editar_simulador_de_deudas_page.dart';
import 'simulador_de_deudas_page.dart';

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

// Clase auxiliar para guardar deuda y progreso
class SimuladorDeudaConProgreso {
  final SimuladorDeuda deuda;
  final double progreso;

  SimuladorDeudaConProgreso(this.deuda, this.progreso);
}

class GuardarSimuladorDeDeudasPage extends StatefulWidget {
  const GuardarSimuladorDeDeudasPage({super.key});

  @override
  State<GuardarSimuladorDeDeudasPage> createState() =>
      _GuardarSimuladorDeDeudasPageState();
}

class _GuardarSimuladorDeDeudasPageState
    extends State<GuardarSimuladorDeDeudasPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false; // Previene el pop normal y navega a resumen
      },
      child: GlobalLayout(
        titulo: 'Deudas Registradas',
        body: DeudasRegistradasContent(),
        mostrarDrawer: true,
        mostrarBotonHome: true,
       // mostrarBotonInforme: true,
        //tipoInforme: 'deuda',
        navIndex: 0,
      ),
    );
  }
}

class DeudasRegistradasContent extends StatefulWidget {
  @override
  State<DeudasRegistradasContent> createState() =>
      _DeudasRegistradasContentState();
}

class _DeudasRegistradasContentState extends State<DeudasRegistradasContent> {
  final SimuladorDeudaRepository _repo = SimuladorDeudaRepository();

  List<SimuladorDeudaConProgreso> _simuladores = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtiene el userId del usuario autenticado
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarSimuladores();
  }

  // Cargar la lista de deudas del usuario desde la base de datos y ordenarlas por progreso
  Future<void> _cargarSimuladores() async {
    setState(() => _isLoading = true);

    List<SimuladorDeudaConProgreso> lista = [];
    if (_userId != null) {
      // 1. Traer deudas normales
      final deudas = await _repo.getSimuladoresDeudaByUser(_userId!);
      // 2. Calcular progreso de cada deuda y armar lista
      lista =
          deudas.map((s) {
            final progreso = calcularProgreso(s);
            return SimuladorDeudaConProgreso(s, progreso);
          }).toList();
      // 3. Ordenar: primero las NO completadas, luego las completadas (y si quieres por progreso)
      lista.sort((a, b) {
        if (a.progreso < 1 && b.progreso >= 1) return -1;
        if (a.progreso >= 1 && b.progreso < 1) return 1;
        return a.progreso.compareTo(b.progreso);
      });
    }

    setState(() {
      _simuladores = lista;
      _isLoading = false;
    });
  }

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
    if (porcentaje > 75 && porcentaje < 100) return 'Casi completado';
    if (porcentaje >= 99.99) return 'Completado';
    if (porcentaje == 100) return 'Completado';
    return '';
  }

  // Eliminar simulador desde la BD
  Future<void> _eliminarSimulador(int id) async {
    if (_userId == null) return;
    final confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Eliminar Deuda',
              style: TextStyle(color: AppColors.textDark),
            ),
            content: const Text('¿Está seguro que desea eliminar esta deuda?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textDark),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
          ),
    );

    if (confirm == true) {
      await _repo.deleteSimuladorDeuda(id, _userId!);
      await _cargarSimuladores();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deuda eliminada correctamente'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height / 2,
            left: 20,
            right: 20,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Ver detalles - abre la pantalla de detalles
  void _verDatosSimulador(SimuladorDeudaConProgreso simuladorProg) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatosDeudaPage(simulador: simuladorProg.deuda),
      ),
    );
    await _cargarSimuladores(); // Por si hubo cambios
  }

  // Editar simulador
  void _editarSimulador(SimuladorDeudaConProgreso simuladorProg) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditarSimuladorDeDeudasPage(simulador: simuladorProg.deuda),
      ),
    );
    await _cargarSimuladores();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0,
        vertical: 8.0,
      ),
      child:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _simuladores.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _simuladores.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final simuladorProg = _simuladores[index];
                  final simulador = simuladorProg.deuda;
                  final progreso = simuladorProg.progreso;
                  final color = _getProgressColor(progreso);
                  final status = _getProgressStatus(progreso);

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _verDatosSimulador(simuladorProg),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    simulador.motivo,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    simulador.periodo,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Monto Total:',
                              'Q${simulador.monto.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Monto Cancelado:',
                              'Q${simulador.montoCancelado.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Fecha Inicio:',
                              _formatDate(simulador.fechaInicio),
                            ),
                            _buildInfoRow(
                              'Fecha Fin:',
                              _formatDate(simulador.fechaFin),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso: ${(progreso * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w500,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progreso,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  color: AppColors.warning,
                                  tooltip: 'Editar',
                                  onPressed:
                                      () => _editarSimulador(simuladorProg),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.error,
                                  tooltip: 'Eliminar',
                                  onPressed:
                                      () => _eliminarSimulador(simulador.id!),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.money_off,
              size: 80,
              color: AppColors.accent.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay deudas registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Agrega una deuda desde el simulador para comenzar a gestionar tus pagos',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimuladorDeudasScreen(),
                  ),
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
              child: const Text('Registrar Deuda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
