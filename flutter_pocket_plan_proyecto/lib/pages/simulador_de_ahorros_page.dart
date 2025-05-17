import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/pages/guardar_simulador_de_ahorros_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_ahorro.dart';

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
  static const Color textField = Color(0xFFF5F5F5);
  static const Color shadow = Color(0x1A000000);
  static const Color iconColor = Color(0xFF2E7D32);
}

class SimuladorAhorrosScreen extends StatelessWidget {
  const SimuladorAhorrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Simulador de Ahorros',
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
      body: const SimuladorAhorrosWidget(),
    );
  }
}

class SimuladorAhorrosWidget extends StatefulWidget {
  const SimuladorAhorrosWidget({Key? key}) : super(key: key);

  @override
  State<SimuladorAhorrosWidget> createState() => _SimuladorAhorrosWidgetState();
}

class _SimuladorAhorrosWidgetState extends State<SimuladorAhorrosWidget> {
  String periodo = 'Seleccione una opción';
  double montoPeriodo = 0.0;
  bool mostrarAyuda = false;

  TextEditingController objetivoController = TextEditingController();
  TextEditingController plazoController = TextEditingController();
  TextEditingController montoController = TextEditingController();
  TextEditingController montoInicialController = TextEditingController();

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

  void actualizarMonto() {
    setState(() {
      montoPeriodo = calcularMontoPorPeriodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Objetivo del Ahorro'),
                  const SizedBox(height: 8),
                  _buildTextField(objetivoController, actualizarMonto),
                  const SizedBox(height: 16),
                  _buildLabel('Periodo de Ahorro'),
                  const SizedBox(height: 8),
                  _buildDropdown(),
                  const SizedBox(height: 16),
                  _buildLabel('Plazo de Ahorro'),
                  const SizedBox(height: 8),
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
                            Text(
                              'Meses',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.help_outline,
                                  size: 20, color: AppColors.iconColor),
                              onPressed: () {
                                setState(() => mostrarAyuda = true);
                                Future.delayed(const Duration(seconds: 4), () {
                                  setState(() => mostrarAyuda = false);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (mostrarAyuda)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Meses en los que desea completar su ahorro',
                        style: TextStyle(
                          color: AppColors.textDark.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Monto a Ahorrar'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    montoController, 
                    actualizarMonto,
                    keyboardType: TextInputType.number,
                    bloquearInteraccion: true,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Monto Inicial del Ahorro'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    montoInicialController, 
                    actualizarMonto,
                    keyboardType: TextInputType.number,
                    bloquearInteraccion: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildResumen(),
          const SizedBox(height: 30),
          _buildBotones(context),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

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
      style: TextStyle(color: AppColors.textDark),
      enableInteractiveSelection: !bloquearInteraccion,
      toolbarOptions: const ToolbarOptions(
        copy: false,
        paste: false,
        cut: false,
        selectAll: false,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        hintText: 'Ingrese el dato...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: periodo,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: AppColors.textField,
      style: TextStyle(color: AppColors.textDark),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: ['Seleccione una opción', 'Quincenal', 'Mensual']
          .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == 'Seleccione una opción'
                        ? Colors.grey.shade500
                        : AppColors.textDark,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          periodo = value!;
          montoPeriodo = calcularMontoPorPeriodo();
        });
      },
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            periodo == 'Seleccione una opción'
                ? 'Seleccione un periodo'
                : 'Ahorro ${periodo == 'Quincenal' ? 'quincenal' : 'mensual'}',
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
    );
  }

  Widget _buildBotones(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.save,
          color: AppColors.success,
          label: 'Guardar',
          onPressed: () {
            final monto = double.tryParse(montoController.text) ?? 0;
            final montoInicial = double.tryParse(montoInicialController.text) ?? 0;
            final plazoMeses = int.tryParse(plazoController.text) ?? 0;

            if (objetivoController.text.isEmpty ||
                monto <= 0 ||
                plazoMeses <= 0 ||
                (periodo != 'Mensual' && periodo != 'Quincenal')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Complete todos los campos correctamente'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }

            final now = DateTime.now();
            final fechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

            simuladoresGuardados.add(SimuladorAhorro(
              objetivo: objetivoController.text,
              monto: monto,
              montoInicial: montoInicial,
              fechaInicio: now,
              fechaFin: fechaFin,
              periodo: periodo,
            ));

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GuardarSimuladorDeAhorrosPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildActionButton(
          icon: Icons.cleaning_services,
          color: AppColors.error,
          label: 'Limpiar',
          onPressed: () {
            setState(() {
              objetivoController.clear();
              montoController.clear();
              plazoController.clear();
              montoInicialController.clear();
              periodo = 'Seleccione una opción';
              montoPeriodo = 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}