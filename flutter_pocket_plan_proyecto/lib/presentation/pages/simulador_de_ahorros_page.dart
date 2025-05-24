import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/repositories/cuota_ahorro_repository.dart';
import '../../data/models/repositories/simulador_ahorro_repository.dart';
import '../../data/models/simulador_ahorro.dart';
import '../../data/models/cuota_ahorro.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';
import 'guardar_simulador_de_ahorros_page.dart';

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
  bool mostrarAdvertencia = false;

  final TextEditingController objetivoController = TextEditingController();
  final TextEditingController plazoController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  final TextEditingController montoInicialController = TextEditingController();

  final SimuladorAhorroRepository _repo = SimuladorAhorroRepository();
  final CuotaAhorroRepository _cuotaRepo = CuotaAhorroRepository();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    montoInicialController.addListener(_checkMontoInicial);
  }

  @override
  void dispose() {
    montoInicialController.removeListener(_checkMontoInicial);
    objetivoController.dispose();
    plazoController.dispose();
    montoController.dispose();
    montoInicialController.dispose();
    super.dispose();
  }

  /// Suma 'meses' a una fecha, manteniendo el día o ajustando al último día del mes si es necesario
  DateTime sumarMeses(DateTime fecha, int meses) {
    int newYear = fecha.year + ((fecha.month - 1 + meses) ~/ 12);
    int newMonth = ((fecha.month - 1 + meses) % 12) + 1;
    int newDay = fecha.day;

    // Ajustar día si el nuevo mes tiene menos días
    int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > lastDayOfNewMonth) {
      newDay = lastDayOfNewMonth;
    }
    return DateTime(newYear, newMonth, newDay);
  }

  void _checkMontoInicial() {
    final montoInicial = double.tryParse(montoInicialController.text) ?? 0;
    setState(() {
      mostrarAdvertencia = montoInicial > 0;
      montoPeriodo = calcularMontoPorPeriodo();
    });
  }

  int calcularTotalPagos({required int plazo, required String periodo}) {
    if (periodo == "Mensual") return plazo;
    if (periodo == "Quincenal") return plazo * 2;
    return 0;
  }

  double calcularMontoPorPeriodo() {
    double monto = double.tryParse(montoController.text) ?? 0;
    double montoInicial = double.tryParse(montoInicialController.text) ?? 0;
    int plazo = int.tryParse(plazoController.text) ?? 1;

    double montoRestante = monto - montoInicial;
    if (montoRestante < 0) montoRestante = 0;

    int periodosTotales = periodo == 'Quincenal' ? plazo * 2 : plazo;
    int periodosRestantes =
        montoInicial > 0 ? periodosTotales - 1 : periodosTotales;
    if (periodosRestantes < 1) periodosRestantes = 1;

    if (periodosTotales == 0) return 0.0;
    if (periodo == 'Quincenal' || periodo == 'Mensual') {
      return montoRestante / periodosRestantes;
    }
    return 0.0;
  }

  void actualizarMonto() {
    setState(() {
      montoPeriodo = calcularMontoPorPeriodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userId = userProvider.usuario?.id;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false;
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.savings,
                    size: isSmallScreen ? 40 : 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Objetivo del Ahorro'),
                      const SizedBox(height: 8),
                      _buildObjetivoTextField(),
                      const SizedBox(height: 16),
                      _buildLabel('Periodo de Ahorro'),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildLabel('Plazo de Ahorro'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(flex: 7, child: _buildPlazoTextField()),
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
                                  icon: Icon(
                                    Icons.help_outline,
                                    size: 20,
                                    color: AppColors.iconColor,
                                  ),
                                  onPressed: () {
                                    setState(() => mostrarAyuda = true);
                                    Future.delayed(
                                      const Duration(seconds: 4),
                                      () {
                                        setState(() => mostrarAyuda = false);
                                      },
                                    );
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
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Monto a Ahorrar'),
                      const SizedBox(height: 8),
                      _buildMontoTextField(),
                      const SizedBox(height: 16),
                      _buildLabel('Monto Inicial del Ahorro'),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMontoInicialTextField(),
                          if (mostrarAdvertencia)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.34),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.warning,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "El monto inicial se registrará automáticamente como tu primer cuota de ahorro.",
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
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
              SizedBox(height: mostrarAdvertencia ? 38 : 16),
              _buildResumen(),
              SizedBox(height: isSmallScreen ? 20 : 30),
              _buildBotones(context, isSmallScreen, userId),
            ],
          ),
        ),
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

  // Campo OBJETIVO (máx 50 caracteres, cualquier caracter)
  Widget _buildObjetivoTextField() {
    return TextFormField(
      controller: objetivoController,
      maxLength: 50,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Ejemplo: Comprar computadora, viaje, etc.',
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el objetivo';
        if (value.length > 50) return 'Máximo 50 caracteres';
        return null;
      },
      onChanged: (_) => actualizarMonto(),
    );
  }

  // Campo PLAZO (entre 1 y 360)
  Widget _buildPlazoTextField() {
    return TextFormField(
      controller: plazoController,
      keyboardType: TextInputType.number,
      maxLength: 3,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: "Ejemplo: 12",
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el plazo';
        final plazo = int.tryParse(value);
        if (plazo == null) return 'Plazo inválido';
        if (plazo < 1) return 'Mínimo 1 mes';
        if (plazo > 360) return 'Máx. 360 meses';
        return null;
      },
      onChanged: (_) => actualizarMonto(),
    );
  }

  // Campo MONTO A AHORRAR (máx Q 999,999.99)
  Widget _buildMontoTextField() {
    return TextFormField(
      controller: montoController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      maxLength: 9,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}(\.\d{0,2})?$')),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixText: 'Q ',
        hintText: "Ejemplo: 12000",
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el monto';
        if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(value)) {
          return 'Formato: hasta 6 enteros y 2 decimales';
        }
        final monto = double.tryParse(value);
        if (monto == null) return 'Monto inválido';
        if (monto <= 0) return 'Debe ser mayor a cero';
        if (monto > 999999.99) return 'Monto demasiado alto';
        return null;
      },
      onChanged: (_) => actualizarMonto(),
    );
  }

  // Campo MONTO INICIAL (igual formato, no mayor al monto a ahorrar)
  Widget _buildMontoInicialTextField() {
    return TextFormField(
      controller: montoInicialController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      maxLength: 9,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}(\.\d{0,2})?$')),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixText: 'Q ',
        hintText: "Ejemplo: 1000",
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el monto inicial';
        if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(value)) {
          return 'Formato: hasta 6 enteros y 2 decimales';
        }
        final inicial = double.tryParse(value);
        final monto = double.tryParse(montoController.text);
        if (inicial == null) return 'Monto inválido';
        if (inicial < 0) return 'No puede ser negativo';
        if (inicial > 999999.99) return 'Monto demasiado alto';
        if (monto != null && inicial > monto)
          return 'No puede ser mayor al monto total';
        return null;
      },
      onChanged: (_) => actualizarMonto(),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: periodo,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: AppColors.textField,
      style: TextStyle(color: AppColors.textDark),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items:
          ['Seleccione una opción', 'Quincenal', 'Mensual'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color:
                      value == 'Seleccione una opción'
                          ? Colors.grey.shade500
                          : AppColors.textDark,
                ),
              ),
            );
          }).toList(),
      validator: (value) {
        if (value == null || value == 'Seleccione una opción') {
          return 'Seleccione el periodo';
        }
        return null;
      },
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
      padding: const EdgeInsets.all(16),
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
          Flexible(
            child: Text(
              periodo == 'Seleccione una opción'
                  ? 'Seleccione un periodo'
                  : 'Ahorro ${periodo == 'Quincenal' ? 'quincenal' : 'mensual'}',
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Flexible(
            child: Text(
              'Q${montoPeriodo.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotones(BuildContext context, bool isSmallScreen, int? userId) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isSmallScreen ? 10 : 20,
      runSpacing: 20,
      children: [
        _buildActionButton(
          icon: Icons.save,
          color: AppColors.success,
          label: 'Guardar',
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Complete todos los campos correctamente',
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No hay usuario logueado.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              return;
            }

            final monto = double.tryParse(montoController.text) ?? 0;
            final montoInicial =
                double.tryParse(montoInicialController.text) ?? 0;
            final plazoMeses = int.tryParse(plazoController.text) ?? 0;

            final now = DateTime.now();
            final fechaFin = sumarMeses(now, plazoMeses);

            // Calcula el total de pagos
            final int totalPagos = calcularTotalPagos(
              plazo: plazoMeses,
              periodo: periodo,
            );

            final simulador = SimuladorAhorro(
              userId: userId,
              objetivo: objetivoController.text,
              monto: monto,
              montoInicial: montoInicial,
              fechaInicio: now,
              fechaFin: fechaFin,
              periodo: periodo,
              progreso: 0.0,
              cuotaSugerida: montoPeriodo,
              totalPagos: totalPagos,
            );

            try {
              int simuladorId = await _repo.insertSimuladorAhorro(simulador);

              if (montoInicial > 0) {
                final cuota = CuotaAhorro(
                  userId: userId,
                  simuladorId: simuladorId,
                  monto: montoInicial,
                  fecha: now,
                );
                await _cuotaRepo.insertCuotaAhorro(cuota);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Simulador guardado correctamente.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuardarSimuladorDeAhorrosPage(),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ocurrió un error al guardar: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          isSmallScreen: isSmallScreen,
        ),
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
              mostrarAdvertencia = false;
            });
          },
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 60 : 70,
          height: isSmallScreen ? 60 : 70,
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
            icon: Icon(
              icon,
              color: Colors.white,
              size: isSmallScreen ? 25 : 30,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      ],
    );
  }
}
