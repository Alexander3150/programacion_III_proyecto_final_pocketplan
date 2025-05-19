import 'package:flutter/material.dart';
import '../widgets/global_components.dart';
import '../../data/models/simulador_deuda.dart';
import 'guardar_simulador_de_deudas_page.dart';

class EditarSimuladorDeDeudasPage extends StatefulWidget {
  final SimuladorDeuda simulador;
  final int index;

  const EditarSimuladorDeDeudasPage({
    super.key,
    required this.simulador,
    required this.index,
  });

  @override
  State<EditarSimuladorDeDeudasPage> createState() => _EditarSimuladorDeDeudasPageState();
}

class _EditarSimuladorDeDeudasPageState extends State<EditarSimuladorDeDeudasPage> {
  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Editar Simulador de Deuda',
      body: EditarSimuladorDeDeudasContent(
        simulador: widget.simulador,
        index: widget.index,
      ),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class EditarSimuladorDeDeudasContent extends StatefulWidget {
  final SimuladorDeuda simulador;
  final int index;

  const EditarSimuladorDeDeudasContent({
    super.key,
    required this.simulador,
    required this.index,
  });

  @override
  State<EditarSimuladorDeDeudasContent> createState() => _EditarSimuladorDeDeudasContentState();
}

class _EditarSimuladorDeDeudasContentState extends State<EditarSimuladorDeDeudasContent> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  late TextEditingController _motivoController;
  late TextEditingController _montoController;
  late TextEditingController _montoCanceladoController;
  late TextEditingController _plazoController;

  String _periodo = 'Seleccione una opción';
  double _cuotaCalculada = 0.0;
  bool _mostrarAyuda = false;
  bool _isCalculating = false;

  // Variables para controlar valores anteriores
  String _lastPeriodo = '';
  String _lastMonto = '';
  String _lastMontoCancelado = '';
  String _lastPlazo = '';

  @override
  void initState() {
    super.initState();
    _motivoController = TextEditingController(text: widget.simulador.motivo);
    _montoController = TextEditingController(
      text: widget.simulador.monto.toStringAsFixed(2),
    );
    _montoCanceladoController = TextEditingController(
      text: widget.simulador.montoCancelado.toStringAsFixed(2),
    );
    _periodo = widget.simulador.periodo;
    final meses = ((widget.simulador.fechaFin.difference(widget.simulador.fechaInicio).inDays) / 30).round();
    _plazoController = TextEditingController(text: meses.toString());
    
    // Inicializar valores anteriores
    _lastPeriodo = _periodo;
    _lastMonto = _montoController.text;
    _lastMontoCancelado = _montoCanceladoController.text;
    _lastPlazo = _plazoController.text;
    
    _cuotaCalculada = _calcularCuota();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _motivoController.dispose();
    _montoController.dispose();
    _montoCanceladoController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  double _calcularCuota() {
    setState(() => _isCalculating = true);
    
    final monto = double.tryParse(_montoController.text) ?? 0;
    final cancelado = double.tryParse(_montoCanceladoController.text) ?? 0;
    final plazo = int.tryParse(_plazoController.text) ?? 1;
    final restante = (monto - cancelado).clamp(0, double.infinity);

    double resultado;
    
    if (_periodo == 'Quincenal') {
      resultado = restante / (plazo * 2);
    } else if (_periodo == 'Mensual') {
      resultado = restante / plazo;
    } else {
      resultado = 0.0;
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    });
    
    return resultado;
  }

  void _actualizarCuotaSiEsNecesario() {
    final currentPeriodo = _periodo;
    final currentMonto = _montoController.text;
    final currentMontoCancelado = _montoCanceladoController.text;
    final currentPlazo = _plazoController.text;

    // Solo actualizar si cambió algún campo relevante
    if (currentPeriodo != _lastPeriodo ||
        currentMonto != _lastMonto ||
        currentMontoCancelado != _lastMontoCancelado ||
        currentPlazo != _lastPlazo) {
      
      setState(() {
        _cuotaCalculada = _calcularCuota();
        // Actualizar valores anteriores
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
    });
  }

  void _guardarCambios() {
    if (!_formKey.currentState!.validate()) {
      _mostrarAlertaCamposIncompletos();
      return;
    }

    final monto = double.tryParse(_montoController.text) ?? 0;
    final cancelado = double.tryParse(_montoCanceladoController.text) ?? 0;
    final plazoMeses = int.tryParse(_plazoController.text) ?? 0;

    if (_motivoController.text.isEmpty ||
        monto <= 0 ||
        plazoMeses <= 0 ||
        (_periodo != 'Mensual' && _periodo != 'Quincenal')) {
      _mostrarAlertaCamposIncompletos();
      return;
    }

    final now = DateTime.now();
    final nuevaFechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

    simuladoresDeudaGuardados[widget.index] = SimuladorDeuda(
      motivo: _motivoController.text,
      monto: monto,
      montoCancelado: cancelado,
      fechaInicio: now,
      fechaFin: nuevaFechaFin,
      periodo: _periodo,
    );

    Navigator.pop(context, true);
  }

  void _mostrarAlertaCamposIncompletos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Por favor, complete todos los campos correctamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
                        (_) {}, // No actualiza el cálculo
                        hintText: 'Ej: Préstamo personal',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un motivo';
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese el plazo';
                                    }
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Plazo inválido';
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
                            'Cantidad de meses en que desea pagar la deuda',
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        prefixText: 'Q ',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el monto';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Monto inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Monto Ya Cancelado'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        _montoCanceladoController,
                        (_) => _actualizarCuotaSiEsNecesario(),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        prefixText: 'Q ',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Monto inválido';
                          }
                          if (double.parse(value) < 0) {
                            return 'No puede ser negativo';
                          }
                          final montoTotal = double.tryParse(_montoController.text) ?? 0;
                          if (double.parse(value) > montoTotal) {
                            return 'No puede ser mayor al total';
                          }
                          return null;
                        },
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
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isCalculating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
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
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.cleaning_services),
                      color: Colors.grey.shade700,
                      onPressed: _limpiarCampos,
                      tooltip: 'Limpiar todos los campos',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
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
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
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
        DropdownMenuItem(
          value: 'Mensual',
          child: Text('Mensual'),
        ),
        DropdownMenuItem(
          value: 'Quincenal',
          child: Text('Quincenal'),
        ),
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
      style: const TextStyle(
        color: Colors.black87,
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