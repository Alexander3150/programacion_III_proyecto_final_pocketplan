// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/simulador_ahorro.dart';
import '../widgets/global_components.dart';
import 'guardar_simulador_de_ahorros_page.dart';

// Colores personalizados para la pantalla de edición
class EditColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF42A5F5);
  static const Color accent = Color(0xFF90CAF9);
  static const Color background = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF0D47A1);
  static const Color textLight = Colors.white;
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
  static const Color textField = Colors.white;
  static const Color cardBackground = Color(0xFFE1F5FE);
  static const Color dividerColor = Color(0xFFBBDEFB);
}

class EditarSimuladorDeAhorrosPage extends StatefulWidget {
  const EditarSimuladorDeAhorrosPage({super.key});

  @override
  State<EditarSimuladorDeAhorrosPage> createState() =>
      _EditarSimuladorDeAhorrosPageState();
}

class _EditarSimuladorDeAhorrosPageState
    extends State<EditarSimuladorDeAhorrosPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para los campos
  late TextEditingController objetivoController;
  late TextEditingController montoController;
  late TextEditingController montoInicialController;
  late TextEditingController plazoController;

  // Variables de control de estado
  String periodo = 'Seleccione una opción';
  late int index;
  double montoPeriodo = 0.0;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  bool _datosCargados = false;
  bool _mostrarAyuda = false; // Controla la visibilidad del mensaje de ayuda

  @override
  void initState() {
    super.initState();
    objetivoController = TextEditingController();
    montoController = TextEditingController();
    montoInicialController = TextEditingController();
    plazoController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo carga los datos una vez
    if (!_datosCargados) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final SimuladorAhorro simulador = args['simulador'];
      index = args['index'];

      // Asignar datos a los controladores
      objetivoController.text = simulador.objetivo;
      montoController.text = simulador.monto.toString();
      montoInicialController.text = simulador.montoInicial.toString();
      fechaInicio = simulador.fechaInicio;
      fechaFin = simulador.fechaFin;
      periodo = simulador.periodo;

      final duracionMeses =
          (fechaFin!.difference(fechaInicio!).inDays / 30).round();
      plazoController.text = duracionMeses.toString();

      montoPeriodo = calcularMontoPorPeriodo();

      _datosCargados = true;
    }
  }

  // Calcula el monto a ahorrar por periodo (mensual o quincenal)
  double calcularMontoPorPeriodo() {
    final monto = double.tryParse(montoController.text) ?? 0;
    final montoInicial = double.tryParse(montoInicialController.text) ?? 0;
    final plazo = int.tryParse(plazoController.text) ?? 1;
    final restante = (monto - montoInicial).clamp(0, double.infinity);

    if (periodo == 'Quincenal') {
      return restante / (plazo * 2);
    } else if (periodo == 'Mensual') {
      return restante / plazo;
    } else {
      return 0.0;
    }
  }

  // Actualiza el cálculo del monto por periodo
  void actualizarMonto() {
    setState(() {
      montoPeriodo = calcularMontoPorPeriodo();
    });
  }

  // Guarda los cambios en el simulador
  void guardarCambios() {
    final monto = double.tryParse(montoController.text) ?? 0;
    final montoInicial = double.tryParse(montoInicialController.text) ?? 0;
    final plazoMeses = int.tryParse(plazoController.text) ?? 0;

    // Validaciones básicas
    if (objetivoController.text.isEmpty ||
        monto <= 0 ||
        plazoMeses <= 0 ||
        (periodo != 'Mensual' && periodo != 'Quincenal')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Por favor, complete todos los campos correctamente',
          ),
          backgroundColor: EditColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final nuevaFechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

    // Reemplaza el simulador editado en la lista global
    simuladoresGuardados[index] = SimuladorAhorro(
      objetivo: objetivoController.text,
      monto: monto,
      montoInicial: montoInicial,
      fechaInicio: now,
      fechaFin: nuevaFechaFin,
      periodo: periodo,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return GlobalLayout(
      titulo: 'Editar Simulador',
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con imagen
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EditColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: EditColors.primary, width: 2),
                  ),
                  child: Icon(
                    Icons.savings,
                    size: isSmallScreen ? 50 : 70,
                    color: EditColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de formulario
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: EditColors.cardBackground,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Plan de Ahorro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: EditColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Objetivo del Ahorro
                      _buildLabel('Objetivo del Ahorro'),
                      _buildTextField(objetivoController, actualizarMonto),
                      const SizedBox(height: 16),

                      // Campo: Periodo a Ahorrar
                      _buildLabel('Periodo a Ahorrar'),
                      _buildDropdown(),
                      const SizedBox(height: 16),

                      // Campo: Plazo de Ahorro
                      _buildLabel('Plazo de Ahorro'),
                      Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildTextField(
                              plazoController,
                              actualizarMonto,
                              keyboardType: TextInputType.number,
                              readOnlyContextMenu: true, // Bloquea copiar/pegar
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                const Text(
                                  'Meses',
                                  style: TextStyle(
                                    color: EditColors.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message:
                                      'Cantidad de meses para completar el ahorro',
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _mostrarAyuda = true;
                                      });
                                      Future.delayed(
                                        const Duration(seconds: 3),
                                        () {
                                          setState(() {
                                            _mostrarAyuda = false;
                                          });
                                        },
                                      );
                                    },
                                    child: const Icon(
                                      Icons.help_outline,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_mostrarAyuda)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ingrese la cantidad de meses para completar su ahorro',
                            style: TextStyle(
                              color: EditColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Campo: Monto a Ahorrar
                      _buildLabel('Monto a Ahorrar'),
                      _buildTextField(
                        montoController,
                        actualizarMonto,
                        keyboardType: TextInputType.number,
                        readOnlyContextMenu: true,
                      ),
                      const SizedBox(height: 16),

                      // Campo: Monto Inicial
                      _buildLabel('Monto Inicial del Ahorro'),
                      _buildTextField(
                        montoInicialController,
                        actualizarMonto,
                        keyboardType: TextInputType.number,
                        readOnlyContextMenu: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de resultado
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: EditColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del Plan',
                        style: TextStyle(
                          color: EditColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: EditColors.dividerColor, thickness: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha de inicio:',
                            style: TextStyle(
                              color: EditColors.textLight,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            fechaInicio != null
                                ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                                : 'No definida',
                            style: TextStyle(
                              color: EditColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha estimada de fin:',
                            style: TextStyle(
                              color: EditColors.textLight,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            fechaFin != null
                                ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                                : 'No definida',
                            style: TextStyle(
                              color: EditColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: EditColors.dividerColor, thickness: 1),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EditColors.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                periodo == 'Mensual'
                                    ? 'Ahorro mensual:'
                                    : periodo == 'Quincenal'
                                    ? 'Ahorro quincenal:'
                                    : 'Seleccione periodo',
                                style: TextStyle(
                                  color: EditColors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              'Q${montoPeriodo.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: EditColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón de guardar
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 24),
                  label: const Text('GUARDAR CAMBIOS'),
                  onPressed: guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EditColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir etiquetas
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: EditColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Construcción de campos de texto con opción para bloquear el menú de copiar/pegar
  Widget _buildTextField(
    TextEditingController controller,
    VoidCallback onChanged, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnlyContextMenu = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      enableInteractiveSelection: !readOnlyContextMenu,
      contextMenuBuilder:
          readOnlyContextMenu
              ? (context, editableTextState) => const SizedBox()
              : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: EditColors.textField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: EditColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: EditColors.primary.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Dropdown para seleccionar el periodo
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: periodo,
      items: const [
        DropdownMenuItem(
          value: 'Seleccione una opción',
          child: Text('Seleccione una opción'),
        ),
        DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
        DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
      ],
      onChanged: (value) {
        setState(() {
          periodo = value!;
          actualizarMonto();
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: EditColors.textField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: EditColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: EditColors.primary.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: EditColors.textField,
      style: TextStyle(color: EditColors.textDark),
    );
  }
}
