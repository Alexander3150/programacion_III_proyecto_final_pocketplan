import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/simulador_ahorro.dart';
import '../widgets/global_components.dart';


// Clase de colores 
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
  static const Color cardBackground = Color(0xFFF1F8E9);
  static const Color dividerColor = Color(0xFFC8E6C9);

  // Colores para la barra de progreso dinámica
  static const Color red = Colors.red;
  static const Color yellow = Colors.amber;
  static const Color blue = Colors.lightBlue;
  static const Color green = Colors.green;
}

// Lista global para guardar simuladores
List<SimuladorAhorro> simuladoresGuardados = [];

class DatosAhorroPage extends StatelessWidget {
  final SimuladorAhorro simulador;

  const DatosAhorroPage({super.key, required this.simulador});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Detalles del Ahorro',
      body: _DatosAhorroContent(simulador: simulador),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class _DatosAhorroContent extends StatefulWidget {
  final SimuladorAhorro simulador;

  const _DatosAhorroContent({required this.simulador});

  @override
  State<_DatosAhorroContent> createState() => _DatosAhorroContentState();
}

class _DatosAhorroContentState extends State<_DatosAhorroContent> {
  final TextEditingController _montoController = TextEditingController();
  DateTime _fechaCuota = DateTime.now();
  List<Map<String, dynamic>> cuotasRegistradas = [];
  double progresoAcumulado = 0.0;
  bool camposBloqueados = false;

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.simulador.montoInicial.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Calcula el progreso acumulado del ahorro basado en cuotas registradas
  double calcularProgreso(SimuladorAhorro simulador) {
    double montoTotalAhorrado = 0;
    for (var cuota in cuotasRegistradas) {
      montoTotalAhorrado += cuota['monto'];
    }
    if (simulador.monto == 0) return 0.0;
    double progreso = (montoTotalAhorrado / simulador.monto);
    return progreso > 1.0 ? 1.0 : progreso;
  }

  // Determina el color de la barra de progreso según el porcentaje
  Color obtenerColorBarra(double progreso) {
    if (progreso <= 0.25) {
      return AppColors.red;
    } else if (progreso <= 0.50) {
      return AppColors.yellow;
    } else if (progreso <= 0.75) {
      return AppColors.blue;
    } else {
      return AppColors.green;
    }
  }

  // Guarda una nueva cuota ingresada
  void _guardarCuota() {
    final montoAhorrado = double.tryParse(_montoController.text) ?? 0;

    if (montoAhorrado <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El monto debe ser mayor que cero'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double montoTotalAhorrado = cuotasRegistradas.fold(
      0,
      (sum, cuota) => sum + cuota['monto'],
    );
    double montoRestante = widget.simulador.monto - montoTotalAhorrado;

    if (montoAhorrado > montoRestante) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes ingresar una cuota mayor al monto restante: Q${montoRestante.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nuevaCuota = {'monto': montoAhorrado, 'fecha': _fechaCuota};

    setState(() {
      cuotasRegistradas.add(nuevaCuota);
      progresoAcumulado = calcularProgreso(widget.simulador);
      widget.simulador.progreso = progresoAcumulado;
      camposBloqueados = progresoAcumulado >= 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          progresoAcumulado >= 1.0
              ? '¡Felicidades! Has completado tu ahorro.'
              : 'Cuota guardada con éxito',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Permite editar una cuota existente
  void _editarCuota(int index) {
    final cuota = cuotasRegistradas[index];
    _montoController.text = cuota['monto'].toStringAsFixed(2);
    setState(() {
      _fechaCuota = cuota['fecha'];
    });
    cuotasRegistradas.removeAt(index);
  }

  // Elimina una cuota
  void _eliminarCuota(int index) {
    setState(() {
      cuotasRegistradas.removeAt(index);
      progresoAcumulado = calcularProgreso(widget.simulador);
      camposBloqueados = progresoAcumulado >= 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuota eliminada con éxito'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final simulador = widget.simulador;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de información del ahorro
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardBackground,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del Plan de Ahorro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Objetivo del Ahorro:', simulador.objetivo),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow('Periodo de Ahorro:', simulador.periodo),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Monto Total a Ahorrar:',
                      'Q${simulador.monto.toStringAsFixed(2)}',
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Monto Inicial:',
                      'Q${simulador.montoInicial.toStringAsFixed(2)}',
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Fecha de Inicio:',
                      _formatDate(simulador.fechaInicio),
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Fecha de Fin:',
                      _formatDate(simulador.fechaFin),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección para agregar cuotas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar Nueva Cuota',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto de la Cuota',
                        labelStyle: const TextStyle(color: AppColors.textDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.textField,
                        prefixIcon: const Icon(
                          Icons.money,
                          color: AppColors.primary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      enabled: !camposBloqueados,
                      onChanged: (_) {
                        setState(() {
                          progresoAcumulado = calcularProgreso(
                            widget.simulador,
                          );
                          camposBloqueados = progresoAcumulado >= 1.0;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha de Ahorro: ${_formatDate(_fechaCuota)}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            onPressed:
                                camposBloqueados
                                    ? null
                                    : () async {
                                      final DateTime?
                                      picked = await showDatePicker(
                                        context: context,
                                        initialDate: _fechaCuota,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: AppColors.primary,
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                              dialogBackgroundColor:
                                                  Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() => _fechaCuota = picked);
                                      }
                                    },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Barra de progreso y botones
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progreso del Ahorro:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Barra de progreso con color dinámico
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progresoAcumulado,
                            backgroundColor: AppColors.accent.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              obtenerColorBarra(progresoAcumulado),
                            ),
                            minHeight: 12,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso: ${(progresoAcumulado * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Q${(widget.simulador.monto * progresoAcumulado).toStringAsFixed(2)} de Q${widget.simulador.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        if (progresoAcumulado >= 1.0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success,
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '¡Felicidades! Has completado tu meta de ahorro.',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botones de acción
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Guardar Cuota',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed:
                                    camposBloqueados ? null : _guardarCuota,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.cleaning_services,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'Limpiar',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                onPressed:
                                    camposBloqueados
                                        ? null
                                        : () {
                                          _montoController.clear();
                                          setState(
                                            () => _fechaCuota = DateTime.now(),
                                          );
                                        },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sección de cuotas registradas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cuotas Registradas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (cuotasRegistradas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No hay cuotas registradas aún',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: cuotasRegistradas.length,
                          separatorBuilder:
                              (context, index) => const Divider(
                                color: AppColors.dividerColor,
                                height: 1,
                              ),
                          itemBuilder: (context, index) {
                            final cuota = cuotasRegistradas[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Q${cuota['monto'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Fecha: ${_formatDate(cuota['fecha'])}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _editarCuota(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => _eliminarCuota(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye una fila de información con título y valor
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
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
