// Importaciones necesarias de Flutter y de otros archivos del proyecto
import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/pages/guardar_simulador_de_ahorros_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_ahorro.dart';

// Definición de una clase para manejar los colores utilizados en la app
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

// Pantalla principal del simulador que utiliza una plantilla llamada GlobalLayout
class SimuladorAhorrosScreen extends StatelessWidget {
  const SimuladorAhorrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Simulador de Ahorros',
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
      body: const SimuladorAhorrosWidget(), // Cuerpo de la pantalla
    );
  }
}

// Widget con estado donde se encuentra el formulario del simulador
class SimuladorAhorrosWidget extends StatefulWidget {
  const SimuladorAhorrosWidget({Key? key}) : super(key: key);

  @override
  State<SimuladorAhorrosWidget> createState() => _SimuladorAhorrosWidgetState();
}

class _SimuladorAhorrosWidgetState extends State<SimuladorAhorrosWidget> {
  // Variables para los datos del simulador
  String periodo = 'Seleccione una opción';
  double montoPeriodo = 0.0;

  // Controladores para los campos de texto
  TextEditingController objetivoController = TextEditingController();
  TextEditingController plazoController = TextEditingController();
  TextEditingController montoController = TextEditingController();
  TextEditingController montoInicialController = TextEditingController();

  bool mostrarAyuda = false; // Bandera para mostrar mensaje de ayuda

  // Calcula el monto que se debe ahorrar en cada periodo según los datos ingresados
  double calcularMontoPorPeriodo() {
    double monto = double.tryParse(montoController.text) ?? 0;
    double montoInicial = double.tryParse(montoInicialController.text) ?? 0;
    int plazo = int.tryParse(plazoController.text) ?? 1;

    double montoRestante = monto - montoInicial;
    if (montoRestante < 0) montoRestante = 0;

    if (periodo == 'Quincenal') {
      return montoRestante / (plazo * 2);
    } else if (periodo == 'Mensual') {
      return montoRestante / plazo;
    } else {
      return 0.0;
    }
  }

  // Actualiza el estado con el nuevo monto por periodo
  void actualizarMonto() {
    setState(() {
      montoPeriodo = calcularMontoPorPeriodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen ilustrativa centrada
          Center(
            child: SizedBox(
              height: 100,
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/190/190411.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campo: Objetivo del Ahorro
          _buildLabel('Objetivo del Ahorro'),
          _buildTextField(objetivoController, actualizarMonto),
          const SizedBox(height: 12),

          // Campo: Selección del periodo (quincenal o mensual)
          _buildLabel('Periodo a Ahorrar'),
          _buildDropdown(),
          const SizedBox(height: 12),

          // Campo: Plazo del ahorro (en meses) con ayuda desplegable
          _buildLabel('Plazo de Ahorro'),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: _buildTextField(
                  plazoController,
                  actualizarMonto,
                  keyboardType: TextInputType.number,
                  bloquearInteraccion: true,
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
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        // Muestra ayuda por 4 segundos
                        setState(() {
                          mostrarAyuda = true;
                        });
                        Future.delayed(const Duration(seconds: 4), () {
                          setState(() {
                            mostrarAyuda = false;
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Mensaje de ayuda sobre el plazo
          if (mostrarAyuda)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                'Aquí debe ingresar la cantidad de meses en que quiere completar su Ahorro',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Campo: Monto objetivo de ahorro
          _buildLabel('Monto a Ahorrar'),
          _buildTextField(
            montoController,
            actualizarMonto,
            keyboardType: TextInputType.number,
            bloquearInteraccion: true,
          ),

          const SizedBox(height: 12),

          // Campo: Monto inicial que se tiene
          _buildLabel('Monto Inicial del Ahorro'),
          _buildTextField(
            montoInicialController,
            actualizarMonto,
            keyboardType: TextInputType.number,
            bloquearInteraccion: true,
          ),

          const SizedBox(height: 20),

          // Resultado calculado: monto a ahorrar por periodo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  periodo == 'Seleccione una opción'
                      ? 'Seleccione un periodo'
                      : 'Monto a ahorrar ${periodo == 'Quincenal' ? 'Quincenalmente' : 'Mensualmente'}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Q${montoPeriodo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Botones: Guardar simulador y limpiar campos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón para guardar simulador
              _buildIconButton(Icons.save, AppColors.success, () {
                final monto = double.tryParse(montoController.text) ?? 0;
                final montoInicial =
                    double.tryParse(montoInicialController.text) ?? 0;
                final plazoMeses = int.tryParse(plazoController.text) ?? 0;

                // Validación de campos
                if (objetivoController.text.isEmpty ||
                    monto <= 0 ||
                    plazoMeses <= 0 ||
                    (periodo != 'Mensual' && periodo != 'Quincenal')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, complete todos los campos correctamente',
                      ),
                    ),
                  );
                  return;
                }

                // Calcular fecha fin del ahorro
                final now = DateTime.now();
                final fechaFin = DateTime(
                  now.year,
                  now.month + plazoMeses,
                  now.day,
                );

                // Agregar simulador a lista global
                simuladoresGuardados.add(
                  SimuladorAhorro(
                    objetivo: objetivoController.text,
                    monto: monto,
                    montoInicial: montoInicial,
                    fechaInicio: now,
                    fechaFin: fechaFin,
                    periodo: periodo,
                  ),
                );

                // Redirige a la página que muestra los simuladores guardados
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GuardarSimuladorDeAhorrosPage(),
                  ),
                );
              }),

              // Botón para limpiar campos
              _buildIconButton(Icons.cleaning_services, AppColors.error, () {
                setState(() {
                  objetivoController.clear();
                  montoController.clear();
                  plazoController.clear();
                  montoInicialController.clear();
                  periodo = 'Seleccione una opción';
                  montoPeriodo = 0.0;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Función para construir etiquetas de texto
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Función para construir campos de texto personalizados
  Widget _buildTextField(
    TextEditingController controller,
    VoidCallback onChangedCallback, {
    TextInputType keyboardType = TextInputType.text,
    bool bloquearInteraccion = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (value) => onChangedCallback(),
      enableInteractiveSelection: !bloquearInteraccion,
      contextMenuBuilder:
          bloquearInteraccion
              ? (context, editableTextState) => const SizedBox.shrink()
              : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        hintText: 'Ingrese el dato...',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: AppColors.textDark, fontSize: 16),
    );
  }

  // Función para construir el menú desplegable para seleccionar el periodo
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: periodo,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      items:
          ['Seleccione una opción', 'Quincenal', 'Mensual'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: AppColors.textDark),
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          periodo = value!;
          montoPeriodo = calcularMontoPorPeriodo();
        });
      },
    );
  }

  // Función para construir botones redondos con icono
  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textLight, size: 36),
        onPressed: onPressed,
      ),
    );
  }
}
