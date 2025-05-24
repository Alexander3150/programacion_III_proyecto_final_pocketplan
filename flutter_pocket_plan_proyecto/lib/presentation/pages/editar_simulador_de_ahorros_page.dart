import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/repositories/cuota_ahorro_repository.dart';
import '../../data/models/repositories/simulador_ahorro_repository.dart';
import '../../data/models/simulador_ahorro.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';

class EditarSimuladorDeAhorrosPage extends StatefulWidget {
  final SimuladorAhorro simulador;

  const EditarSimuladorDeAhorrosPage({super.key, required this.simulador});

  @override
  State<EditarSimuladorDeAhorrosPage> createState() =>
      _EditarSimuladorDeAhorrosPageState();
}

class _EditarSimuladorDeAhorrosPageState
    extends State<EditarSimuladorDeAhorrosPage> {
  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Editar Simulador de Ahorro',
      body: EditarSimuladorDeAhorrosContent(simulador: widget.simulador),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class EditarSimuladorDeAhorrosContent extends StatefulWidget {
  final SimuladorAhorro simulador;

  const EditarSimuladorDeAhorrosContent({super.key, required this.simulador});

  @override
  State<EditarSimuladorDeAhorrosContent> createState() =>
      _EditarSimuladorDeAhorrosContentState();
}

class _EditarSimuladorDeAhorrosContentState
    extends State<EditarSimuladorDeAhorrosContent> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _objetivoController;
  late TextEditingController _montoController;
  late TextEditingController _plazoController;

  String _periodo = 'Seleccione una opción';
  double _cuotaSugerida = 0.0;
  bool _mostrarAyuda = false;

  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late int? _simuladorId;
  int? _userId;
  late SimuladorAhorroRepository _repo;
  final CuotaAhorroRepository _cuotaRepo = CuotaAhorroRepository();

  bool _esAhorroCompletado = false;
  double _totalYaAhorrado = 0.0;
  int _totalPagos = 0;
  int _cuotasRegistradas = 0;
  int _pagosPendientes = 0;

  @override
  void initState() {
    super.initState();
    _repo = SimuladorAhorroRepository();
    _simuladorId = widget.simulador.id;
    _objetivoController = TextEditingController(
      text: widget.simulador.objetivo,
    );
    _montoController = TextEditingController(
      text: widget.simulador.monto.toStringAsFixed(2),
    );
    _periodo = widget.simulador.periodo;
    _fechaInicio = widget.simulador.fechaInicio;
    _fechaFin = widget.simulador.fechaFin;

    // Calcula los meses exactos para el plazo
    final meses = calcularMeses(_fechaInicio, _fechaFin);
    _plazoController = TextEditingController(text: meses.toString());
  }

  int calcularMeses(DateTime inicio, DateTime fin) {
    int years = fin.year - inicio.year;
    int months = fin.month - inicio.month;
    int totalMonths = years * 12 + months;
    if (fin.day < inicio.day) {
      totalMonths--;
    }
    return totalMonths > 0 ? totalMonths : 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarTotalYaAhorradoYCuotas();
  }

  Future<void> _cargarTotalYaAhorradoYCuotas() async {
    if (_userId != null && _simuladorId != null) {
      final total = await _cuotaRepo.getTotalAhorradoPorSimulador(
        _simuladorId!,
        _userId!,
      );
      final cuotasList = await _cuotaRepo.getCuotasPorSimuladorId(
        _simuladorId!,
        _userId!,
      );
      setState(() {
        _totalYaAhorrado = total;
        _cuotasRegistradas = cuotasList.length;
        final montoObj =
            double.tryParse(_montoController.text) ?? widget.simulador.monto;
        _esAhorroCompletado = _totalYaAhorrado >= montoObj && montoObj > 0;
        _actualizarCuotaSugerida();
      });
    }
  }

  int _calcularTotalPagos() {
    final plazo = int.tryParse(_plazoController.text) ?? 1;
    if (_periodo == 'Quincenal') return plazo * 2;
    if (_periodo == 'Mensual') return plazo;
    return 1;
  }

  void _actualizarCuotaSugerida() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final restante = (monto - _totalYaAhorrado).clamp(0, double.infinity);

    _totalPagos = _calcularTotalPagos();
    int pagosPendientes = (_totalPagos - _cuotasRegistradas);
    if (pagosPendientes < 0) pagosPendientes = 0;
    _pagosPendientes = pagosPendientes;

    setState(() {
      _cuotaSugerida = pagosPendientes > 0 ? restante / pagosPendientes : 0.0;
    });
  }

  void _onAnyFieldChanged([String? _]) {
    _actualizarCuotaSugerida();
  }

  void _limpiarCampos() {
    setState(() {
      _objetivoController.clear();
      _montoController.clear();
      _plazoController.clear();
      _periodo = 'Seleccione una opción';
      _cuotaSugerida = 0.0;
      _pagosPendientes = 0;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarAlertaCamposIncompletos();
      return;
    }
    if (_userId == null) {
      _mostrarAlertaCamposIncompletos();
      return;
    }
    final monto = double.tryParse(_montoController.text) ?? 0;
    final plazoMeses = int.tryParse(_plazoController.text) ?? 0;

    if (_objetivoController.text.isEmpty ||
        monto <= 0 ||
        plazoMeses <= 0 ||
        (_periodo != 'Mensual' && _periodo != 'Quincenal')) {
      _mostrarAlertaCamposIncompletos();
      return;
    }

    final now = _fechaInicio;
    final nuevaFechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

    final ahorroActualizado = widget.simulador.copyWith(
      objetivo: _objetivoController.text,
      monto: monto,
      fechaInicio: now,
      fechaFin: nuevaFechaFin,
      periodo: _periodo,
      cuotaSugerida: _cuotaSugerida,
    );

    await _repo.updateSimuladorAhorro(ahorroActualizado, _userId!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cambios guardados correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, true);
  }

  void _mostrarAlertaCamposIncompletos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Por favor, complete todos los campos correctamente',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.red[400],
      ),
    );
  }

  @override
  void dispose() {
    _objetivoController.dispose();
    _montoController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final bool camposHabilitados = !_esAhorroCompletado;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  child: Column(
                    children: [
                      _buildLabel('Objetivo de Ahorro'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _objetivoController,
                        maxLength: 50,
                        onChanged: _onAnyFieldChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un objetivo';
                          }
                          if (value.length > 50) {
                            return 'Máximo 50 caracteres';
                          }
                          return null;
                        },
                        enabled: true,
                        buildCounter:
                            (
                              context, {
                              required int currentLength,
                              required bool isFocused,
                              int? maxLength,
                            }) => null, // Oculta el contador
                        decoration: InputDecoration(
                          hintText: 'Ej: Comprar laptop',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Periodo de Ahorro'),
                      const SizedBox(height: 8),
                      _buildDropdown(camposHabilitados),
                      const SizedBox(height: 16),
                      _buildLabel('Plazo de Ahorro'),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: TextFormField(
                                  controller: _plazoController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                  onChanged: (_) => _onAnyFieldChanged(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el plazo';
                                    }
                                    int? plazo = int.tryParse(value);
                                    if (plazo == null || plazo <= 0) {
                                      return 'Plazo inválido';
                                    }
                                    if (plazo > 360) {
                                      return 'Máx. 360 meses';
                                    }
                                    return null;
                                  },
                                  enabled: camposHabilitados,
                                  buildCounter:
                                      (
                                        context, {
                                        required int currentLength,
                                        required bool isFocused,
                                        int? maxLength,
                                      }) => null, // Oculta contador
                                  decoration: InputDecoration(
                                    hintText: 'Ej: 12',
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Container(
                                constraints: BoxConstraints(
                                  minWidth: isSmallScreen ? 70 : 80,
                                ),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Meses',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.help_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    !camposHabilitados
                                        ? null
                                        : () {
                                          if (!mounted) return;
                                          setState(() => _mostrarAyuda = true);
                                          Future.delayed(
                                            const Duration(seconds: 3),
                                            () {
                                              if (!mounted) return;
                                              setState(
                                                () => _mostrarAyuda = false,
                                              );
                                            },
                                          );
                                        },
                              ),
                            ],
                          );
                        },
                      ),
                      if (_mostrarAyuda)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Cantidad de meses para completar el ahorro (máx. 360)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  child: Column(
                    children: [
                      _buildLabel('Monto Total a Ahorrar'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength: 9,
                        onChanged: (_) => _onAnyFieldChanged(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                          LengthLimitingTextInputFormatter(9),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el monto';
                          }
                          // Permite hasta 6 enteros y 2 decimales
                          if (!RegExp(
                            r'^\d{1,6}(\.\d{1,2})?$',
                          ).hasMatch(value)) {
                            return 'Máx. 6 enteros y 2 decimales';
                          }
                          double? monto = double.tryParse(value);
                          if (monto == null || monto <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                        enabled: camposHabilitados,
                        buildCounter:
                            (
                              context, {
                              required int currentLength,
                              required bool isFocused,
                              int? maxLength,
                            }) => null,
                        decoration: InputDecoration(prefixText: 'Q '),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Total ya ahorrado'),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        enabled: false,
                        controller: TextEditingController(
                          text: 'Q${_totalYaAhorrado.toStringAsFixed(2)}',
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (_esAhorroCompletado)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Ahorro completado. Solo puede editar el objetivo.',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // CARD VALOR ESTIMADO + PAGOS PENDIENTES
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColorDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade800.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUOTA ${_periodo == 'Quincenal' ? 'QUINCENAL' : 'MENSUAL'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _periodo == 'Seleccione una opción'
                                    ? 'Seleccione periodo'
                                    : 'Valor estimado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            'Q${_cuotaSugerida.toStringAsFixed(2)}',
                            key: ValueKey<double>(_cuotaSugerida),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // PAGOS PENDIENTES ABAJO DEL VALOR ESTIMADO
                    Row(
                      children: [
                        const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pagos pendientes: $_pagosPendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'GUARDAR CAMBIOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColorDark,
        fontSize: 14,
      ),
    );
  }

  Widget _buildDropdown(bool enabled) {
    return DropdownButtonFormField<String>(
      value: _periodo,
      items: const [
        DropdownMenuItem(
          value: 'Seleccione una opción',
          child: Text('Seleccione una opción'),
        ),
        DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
        DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
      ],
      onChanged:
          enabled
              ? (value) {
                setState(() {
                  _periodo = value!;
                  _actualizarCuotaSugerida();
                });
              }
              : null,
      validator: (value) {
        if (value == null || value == 'Seleccione una opción') {
          return 'Seleccione un periodo';
        }
        return null;
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade700,
        fontSize: 16,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: Theme.of(context).primaryColor,
      ),
      isExpanded: true,
    );
  }
}
