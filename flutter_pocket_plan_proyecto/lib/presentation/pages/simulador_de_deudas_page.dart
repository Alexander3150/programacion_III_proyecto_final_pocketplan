import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/repositories/cuota_pago_repository.dart';
import '../../data/models/repositories/simulador_deuda_repository.dart';
import '../../data/models/simulador_deuda.dart';
import '../../data/models/cuota_pago.dart';

import '../providers/user_provider.dart';
import '../widgets/global_components.dart';
import 'guardar_simulador_de_deudas_page.dart';

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

class SimuladorDeudasScreen extends StatelessWidget {
  const SimuladorDeudasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Registro de Deudas',
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
      body: const SimuladorDeudasWidget(),
    );
  }
}

class SimuladorDeudasWidget extends StatefulWidget {
  const SimuladorDeudasWidget({super.key});

  @override
  State<SimuladorDeudasWidget> createState() => _SimuladorDeudasWidgetState();
}

class _SimuladorDeudasWidgetState extends State<SimuladorDeudasWidget> {
  String periodo = 'Seleccione una opción';
  double cuotaPeriodo = 0.0;

  final TextEditingController motivoController = TextEditingController();
  final TextEditingController plazoController = TextEditingController();
  final TextEditingController montoController = TextEditingController();
  final TextEditingController montoCanceladoController =
      TextEditingController();

  bool mostrarAyuda = false;
  final SimuladorDeudaRepository _repo = SimuladorDeudaRepository();
  final CuotaPagoRepository _cuotaRepo = CuotaPagoRepository();

  final _formKey = GlobalKey<FormState>();

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

  /// Calcula el total de pagos (cuotas) para registrar en el simulador
  int calcularTotalPagos({required int plazo, required String periodo}) {
    if (periodo == 'Mensual') return plazo;
    if (periodo == 'Quincenal') return plazo * 2;
    return 0;
  }

  double calcularCuota() {
    double total = double.tryParse(montoController.text) ?? 0;
    double cancelado = double.tryParse(montoCanceladoController.text) ?? 0;
    int plazo = int.tryParse(plazoController.text) ?? 1;

    double restante = total - cancelado;
    if (restante < 0) restante = 0;

    int totalPagos = periodo == 'Quincenal' ? plazo * 2 : plazo;
    int pagosRestantes = cancelado > 0 ? totalPagos - 1 : totalPagos;
    if (pagosRestantes < 1) pagosRestantes = 1;

    if (totalPagos == 0) return 0.0;
    if (periodo == 'Quincenal' || periodo == 'Mensual') {
      return restante / pagosRestantes;
    }
    return 0.0;
  }

  void actualizarCuota() {
    setState(() {
      cuotaPeriodo = calcularCuota();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userId = userProvider.usuario?.id;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 380 ? 8.0 : 20.0;
    final cardPadding = screenWidth < 380 ? 8.0 : 16.0;
    final resumenPadding = screenWidth < 380 ? 12.0 : 24.0;
    final btnSize = screenWidth < 360 ? 54.0 : 70.0;
    final btnIconSize = screenWidth < 360 ? 22.0 : 30.0;
    final btnTextFont = screenWidth < 360 ? 13.0 : 15.0;

    // <<<--- INICIO DEL WillPopScope
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false;
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Motivo de la Deuda'),
                      const SizedBox(height: 8),
                      _buildMotivoTextField(),
                      const SizedBox(height: 16),
                      _buildLabel('Periodo de Pago'),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildLabel('Plazo de Pago'),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 7, child: _buildPlazoTextField()),
                          SizedBox(width: screenWidth < 380 ? 4 : 8),
                          Text(
                            'Meses',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth < 380 ? 13 : 15,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.help_outline,
                              size: screenWidth < 380 ? 18 : 20,
                              color: AppColors.accent,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => mostrarAyuda = !mostrarAyuda);
                              if (!mostrarAyuda) return;
                              Future.delayed(const Duration(seconds: 4), () {
                                if (mounted)
                                  setState(() => mostrarAyuda = false);
                              });
                            },
                          ),
                        ],
                      ),
                      if (mostrarAyuda)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 2.0),
                          child: Text(
                            'Cantidad de meses en los que desea pagar la deuda.\nEjemplo: 12 meses equivale a un año de pago.',
                            style: TextStyle(
                              color: AppColors.textDark.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.start,
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
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Monto de la Deuda'),
                      const SizedBox(height: 8),
                      _buildMontoTextField(),
                      const SizedBox(height: 16),
                      _buildLabel('Monto ya Cancelado de la Deuda'),
                      const SizedBox(height: 8),
                      _buildMontoCanceladoTextField(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildResumen(resumenPadding, screenWidth),
              const SizedBox(height: 30),
              _buildBotones(context, btnSize, btnIconSize, btnTextFont, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  /// CAMPO: MOTIVO (max 50 caracteres, cualquier carácter)
  Widget _buildMotivoTextField() {
    return TextFormField(
      controller: motivoController,
      maxLength: 50,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.textField,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: "Ejemplo: Préstamo personal, tarjeta, carro...",
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el motivo';
        if (value.length > 50) return 'Máximo 50 caracteres';
        return null;
      },
      onChanged: (_) => actualizarCuota(),
    );
  }

  /// CAMPO: PLAZO (meses, entre 1 y 360)
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
        if (plazo > 360) return 'Máx. 360 meses (30 años)';
        return null;
      },
      onChanged: (_) => actualizarCuota(),
    );
  }

  /// CAMPO: MONTO DEUDA (máx Q 999,999.99, 6 enteros y 2 decimales)
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
          return 'Hasta 6 enteros y 2 decimales';
        }
        final monto = double.tryParse(value);
        if (monto == null) return 'Monto inválido';
        if (monto < 0) return 'No puede ser negativo';
        if (monto > 999999.99) return 'Monto demasiado alto';
        return null;
      },
      onChanged: (_) => actualizarCuota(),
    );
  }

  /// CAMPO: MONTO CANCELADO (máx Q 999,999.99, <= monto de deuda, 6 enteros y 2 decimales)
  Widget _buildMontoCanceladoTextField() {
    return TextFormField(
      controller: montoCanceladoController,
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
        hintText: "Ejemplo: 3000",
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingrese el monto cancelado';
        if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(value)) {
          return 'Hasta 6 enteros y 2 decimales';
        }
        final cancelado = double.tryParse(value);
        final deuda = double.tryParse(montoController.text);
        if (cancelado == null) return 'Monto inválido';
        if (cancelado < 0) return 'No puede ser negativo';
        if (cancelado > 999999.99) return 'Monto demasiado alto';
        if (deuda != null && cancelado > deuda)
          return 'No puede superar el monto de la deuda';
        return null;
      },
      onChanged: (_) => actualizarCuota(),
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
      style: const TextStyle(color: AppColors.textDark),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
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
          cuotaPeriodo = calcularCuota();
        });
      },
    );
  }

  Widget _buildResumen(double resumenPadding, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(resumenPadding),
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
                  : 'Cuota a pagar ${periodo == 'Quincenal' ? 'Quincenalmente' : 'Mensualmente'}',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth < 380 ? 15 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Q${cuotaPeriodo.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 380 ? 15 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotones(
    BuildContext context,
    double btnSize,
    double btnIconSize,
    double btnTextFont,
    int? userId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.save,
          color: AppColors.success,
          label: 'Guardar',
          btnSize: btnSize,
          iconSize: btnIconSize,
          fontSize: btnTextFont,
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
            final cancelado =
                double.tryParse(montoCanceladoController.text) ?? 0;
            final plazoMeses = int.tryParse(plazoController.text) ?? 0;

            final now = DateTime.now();
            // --- Usar sumarMeses para obtener fecha fin exacta ---
            final fechaFin = sumarMeses(now, plazoMeses);
            final int totalPagos = calcularTotalPagos(
              plazo: plazoMeses,
              periodo: periodo,
            );

            final deuda = SimuladorDeuda(
              motivo: motivoController.text,
              monto: monto,
              montoCancelado: cancelado,
              fechaInicio: now,
              fechaFin: fechaFin,
              periodo: periodo,
              userId: userId,
              progreso: 0.0,
              pagoSugerido: cuotaPeriodo,
              totalPagos: totalPagos,
            );
            int deudaId = await _repo.insertSimuladorDeuda(deuda);

            if (cancelado > 0) {
              final cuota = CuotaPago(
                userId: userId,
                simuladorId: deudaId,
                monto: cancelado,
                fecha: now,
              );
              await _cuotaRepo.insertCuotaPago(cuota, userId);
            }

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GuardarSimuladorDeDeudasPage(),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.cleaning_services,
          color: AppColors.error,
          label: 'Limpiar',
          btnSize: btnSize,
          iconSize: btnIconSize,
          fontSize: btnTextFont,
          onPressed: () {
            setState(() {
              motivoController.clear();
              montoController.clear();
              plazoController.clear();
              montoCanceladoController.clear();
              periodo = 'Seleccione una opción';
              cuotaPeriodo = 0.0;
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
    required double btnSize,
    required double iconSize,
    required double fontSize,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: btnSize,
          height: btnSize,
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
            icon: Icon(icon, color: Colors.white, size: iconSize),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
