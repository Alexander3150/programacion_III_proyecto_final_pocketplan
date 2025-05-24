import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/cuota_pago_repository.dart';
import '../../data/models/repositories/simulador_deuda_repository.dart';
import '../widgets/global_components.dart';
import '../../data/models/simulador_deuda.dart';
import '../providers/user_provider.dart';

class EditarSimuladorDeDeudasPage extends StatefulWidget {
  final SimuladorDeuda simulador;

  const EditarSimuladorDeDeudasPage({super.key, required this.simulador});

  @override
  State<EditarSimuladorDeDeudasPage> createState() =>
      _EditarSimuladorDeDeudasPageState();
}

class _EditarSimuladorDeDeudasPageState
    extends State<EditarSimuladorDeDeudasPage> {
  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Editar Simulador de Deuda',
      body: EditarSimuladorDeDeudasContent(simulador: widget.simulador),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class EditarSimuladorDeDeudasContent extends StatefulWidget {
  final SimuladorDeuda simulador;

  const EditarSimuladorDeDeudasContent({super.key, required this.simulador});

  @override
  State<EditarSimuladorDeDeudasContent> createState() =>
      _EditarSimuladorDeDeudasContentState();
}

class _EditarSimuladorDeDeudasContentState
    extends State<EditarSimuladorDeDeudasContent> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  late TextEditingController _motivoController;
  late TextEditingController _montoController;
  late TextEditingController _montoCanceladoController;
  late TextEditingController _plazoController;

  String _periodo = 'Seleccione una opción';
  double _cuotaCalculada = 0.0;
  int _pagosTotales = 0;
  int _cuotasPagadas = 0;
  int _pagosPendientes = 0;

  bool _mostrarAyuda = false;
  bool _isCalculating = false;

  late SimuladorDeudaRepository _repo;
  late CuotaPagoRepository _cuotaRepo;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late int? _simuladorId;
  int? _userId;

  String _lastPeriodo = '';
  String _lastMonto = '';
  String _lastMontoCancelado = '';
  String _lastPlazo = '';

  @override
  void initState() {
    super.initState();
    _repo = SimuladorDeudaRepository();
    _cuotaRepo = CuotaPagoRepository();
    _simuladorId = widget.simulador.id;
    _motivoController = TextEditingController(text: widget.simulador.motivo);
    _montoController = TextEditingController(
      text: widget.simulador.monto.toStringAsFixed(2),
    );
    _montoCanceladoController = TextEditingController(
      text: widget.simulador.montoCancelado.toStringAsFixed(2),
    );
    _periodo = widget.simulador.periodo;
    _fechaInicio = widget.simulador.fechaInicio;
    _fechaFin = widget.simulador.fechaFin;

    // --- Cálculo correcto de meses ---
    final meses = calcularMeses(_fechaInicio, _fechaFin);
    _plazoController = TextEditingController(text: meses.toString());

    _lastPeriodo = _periodo;
    _lastMonto = _montoController.text;
    _lastMontoCancelado = _montoCanceladoController.text;
    _lastPlazo = _plazoController.text;
  }

  int calcularMeses(DateTime inicio, DateTime fin) {
    int years = fin.year - inicio.year;
    int months = fin.month - inicio.month;
    int totalMonths = years * 12 + months;
    if (fin.day < inicio.day) {
      totalMonths--;
    }
    return totalMonths;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarCuotasYCalcular();
  }

  Future<void> _cargarCuotasYCalcular() async {
    if (_simuladorId == null || _userId == null) return;
    final cuotas = await _cuotaRepo.getCuotasPorSimuladorId(
      _simuladorId!,
      _userId!,
    );
    final cuotasPagadas = cuotas.length;

    setState(() {
      _cuotasPagadas = cuotasPagadas;
      _pagosTotales = _calcularTotalPagos();
      _pagosPendientes = (_pagosTotales - _cuotasPagadas).clamp(
        1,
        _pagosTotales,
      );
      _cuotaCalculada = _calcularCuota();
    });
  }

  int _calcularTotalPagos() {
    final plazo = int.tryParse(_plazoController.text) ?? 1;
    if (_periodo == 'Quincenal') return plazo * 2;
    if (_periodo == 'Mensual') return plazo;
    return 1;
  }

  double _calcularCuota() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final cancelado = double.tryParse(_montoCanceladoController.text) ?? 0;
    final restante = (monto - cancelado).clamp(0, double.infinity);

    return _pagosPendientes > 0 ? restante / _pagosPendientes : 0.0;
  }

  void _actualizarCuotaSiEsNecesario() async {
    final currentPeriodo = _periodo;
    final currentMonto = _montoController.text;
    final currentMontoCancelado = _montoCanceladoController.text;
    final currentPlazo = _plazoController.text;

    if (currentPeriodo != _lastPeriodo ||
        currentMonto != _lastMonto ||
        currentMontoCancelado != _lastMontoCancelado ||
        currentPlazo != _lastPlazo) {
      await _cargarCuotasYCalcular();
      setState(() {
        _lastPeriodo = currentPeriodo;
        _lastMonto = currentMonto;
        _lastMontoCancelado = currentMontoCancelado;
        _lastPlazo = currentPlazo;
      });
    }
  }

  void _limpiarCampos() {
    setState(() {
      _motivoController.clear();
      _montoController.clear();
      _montoCanceladoController.clear();
      _plazoController.clear();
      _periodo = 'Seleccione una opción';
      _cuotaCalculada = 0.0;
      _pagosTotales = 0;
      _pagosPendientes = 0;
      _cuotasPagadas = 0;
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
    final cancelado = double.tryParse(_montoCanceladoController.text) ?? 0;
    final plazoMeses = int.tryParse(_plazoController.text) ?? 0;

    if (_motivoController.text.isEmpty ||
        monto <= 0 ||
        plazoMeses <= 0 ||
        plazoMeses > 360 ||
        (_periodo != 'Mensual' && _periodo != 'Quincenal')) {
      _mostrarAlertaCamposIncompletos();
      return;
    }

    if (cancelado > monto) {
      _mostrarAlertaCamposIncompletos();
      return;
    }

    final now = _fechaInicio;
    final nuevaFechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

    final deudaActualizada = widget.simulador.copyWith(
      motivo: _motivoController.text,
      monto: monto,
      montoCancelado: cancelado,
      fechaInicio: now,
      fechaFin: nuevaFechaFin,
      periodo: _periodo,
      pagoSugerido: _cuotaCalculada,
    );

    await _repo.updateSimuladorDeuda(deudaActualizada, _userId!);

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
                      _buildLabel('Motivo de la Deuda'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _motivoController,
                        (_) {},
                        hintText: 'Ej: Préstamo personal',
                        maxLength: 50, // Limita a 50 caracteres
                        // No pongas inputFormatters para dejar pasar cualquier caracter
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un motivo';
                          }
                          if (value.length > 50) {
                            return 'Máximo 50 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildLabel('Periodo de Pago'),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildLabel('Plazo de Pago'),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  _plazoController,
                                  (_) => _actualizarCuotaSiEsNecesario(),
                                  keyboardType: TextInputType.number,
                                  hintText: 'Ej: 12',
                                  maxLength: 3,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el plazo';
                                    }
                                    final plazo = int.tryParse(value);
                                    if (plazo == null || plazo <= 0) {
                                      return 'Plazo inválido';
                                    }
                                    if (plazo > 360) {
                                      return 'Máximo 360 meses';
                                    }
                                    return null;
                                  },
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
                                onPressed: () {
                                  if (!mounted) return;
                                  setState(() => _mostrarAyuda = true);
                                  Future.delayed(
                                    const Duration(seconds: 3),
                                    () {
                                      if (!mounted) return;
                                      setState(() => _mostrarAyuda = false);
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
                            'Cantidad de meses en que desea pagar la deuda (máx. 360).',
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
                      _buildLabel('Monto Total de la Deuda'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _montoController,
                        (_) => _actualizarCuotaSiEsNecesario(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength:
                            9, // 6 enteros + punto + 2 decimales = 9 caracteres
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(9),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        prefixText: 'Q ',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el monto';
                          }
                          // Acepta máximo 6 enteros y 2 decimales
                          if (!RegExp(
                            r'^\d{1,6}(\.\d{1,2})?$',
                          ).hasMatch(value)) {
                            return 'Máx. 6 enteros y 2 decimales';
                          }
                          double? monto = double.tryParse(value);
                          if (monto == null || monto <= 0) {
                            return 'Monto inválido';
                          }
                          // Validación de monto cancelado (opcional)
                          double? cancelado = double.tryParse(
                            _montoCanceladoController.text,
                          );
                          if (cancelado != null && cancelado > monto) {
                            return 'Cancelado mayor al total';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildLabel('Monto Ya Cancelado'),
                      const SizedBox(height: 8),
                      // --- Campo SOLO LECTURA ---
                      TextFormField(
                        controller: _montoCanceladoController,
                        enabled: false,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'Q ',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                child: Row(
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
                          const SizedBox(height: 8),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          _isCalculating
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Q${_cuotaCalculada.toStringAsFixed(2)}',
                                key: ValueKey<double>(_cuotaCalculada),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildTextField(
    TextEditingController controller,
    ValueChanged<String> onChanged, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? prefixText,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      buildCounter:
          (
            context, {
            required int currentLength,
            required bool isFocused,
            int? maxLength,
          }) => null,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.black87, fontSize: 16),
    );
  }

  Widget _buildDropdown() {
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
      onChanged: (value) {
        setState(() {
          _periodo = value!;
          _actualizarCuotaSiEsNecesario();
        });
      },
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
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.black87, fontSize: 16),
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
