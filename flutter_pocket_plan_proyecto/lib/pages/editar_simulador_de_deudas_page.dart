import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/pages/datos_deuda_page.dart';
import 'package:flutter_pocket_plan_proyecto/models/simulador_deuda.dart';
import 'package:flutter_pocket_plan_proyecto/pages/guardar_simulador_de_deudas_page.dart';
import 'package:flutter_pocket_plan_proyecto/pages/simulador_de_deudas_page.dart';
import '../models/simulador_deuda.dart';

class EditarSimuladorDeDeudasPage extends StatefulWidget {
  final SimuladorDeuda simulador;
  final int index;

  const EditarSimuladorDeDeudasPage({
    super.key,
    required this.simulador,
    required this.index,
  });

  @override
  State<EditarSimuladorDeDeudasPage> createState() =>
      _EditarSimuladorDeDeudasPageState();
}

class _EditarSimuladorDeDeudasPageState
    extends State<EditarSimuladorDeDeudasPage> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  late TextEditingController motivoController;
  late TextEditingController montoController;
  late TextEditingController montoCanceladoController;
  late TextEditingController plazoController;

  String periodo = 'Seleccione una opción';
  double cuotaCalculada = 0.0;
  bool mostrarAyuda = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    motivoController = TextEditingController(text: widget.simulador.motivo);
    montoController = TextEditingController(
        text: widget.simulador.monto.toStringAsFixed(2));
    montoCanceladoController = TextEditingController(
        text: widget.simulador.montoCancelado.toStringAsFixed(2));
    periodo = widget.simulador.periodo;
    final meses = ((widget.simulador.fechaFin.difference(widget.simulador.fechaInicio).inDays) / 30).round();
    plazoController = TextEditingController(text: meses.toString());
    cuotaCalculada = _calcularCuota();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _calcularCuota() {
    setState(() => _isCalculating = true);
    
    final monto = double.tryParse(montoController.text) ?? 0;
    final cancelado = double.tryParse(montoCanceladoController.text) ?? 0;
    final plazo = int.tryParse(plazoController.text) ?? 1;
    final restante = (monto - cancelado).clamp(0, double.infinity);

    double resultado;
    
    if (periodo == 'Quincenal') {
      resultado = restante / (plazo * 2);
    } else if (periodo == 'Mensual') {
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

  void _actualizarCuota() {
    setState(() {
      cuotaCalculada = _calcularCuota();
    });
  }

  void _guardarCambios() {
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(montoController.text) ?? 0;
    final cancelado = double.tryParse(montoCanceladoController.text) ?? 0;
    final plazoMeses = int.tryParse(plazoController.text) ?? 0;

    if (motivoController.text.isEmpty ||
        monto <= 0 ||
        plazoMeses <= 0 ||
        (periodo != 'Mensual' && periodo != 'Quincenal')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, complete todos los campos correctamente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 20,
            right: 20,
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final nuevaFechaFin = DateTime(now.year, now.month + plazoMeses, now.day);

    simuladoresDeudaGuardados[widget.index] = SimuladorDeuda(
      motivo: motivoController.text,
      monto: monto,
      montoCancelado: cancelado,
      fechaInicio: now,
      fechaFin: nuevaFechaFin,
      periodo: periodo,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Deuda'),
          centerTitle: true,
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _guardarCambios,
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE8F5E9),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildLabel('Motivo de la Deuda'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          motivoController,
                          _actualizarCuota,
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                plazoController,
                                _actualizarCuota,
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
                            const SizedBox(width: 12),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Meses',
                                  style: TextStyle(
                                    color: Colors.grey.shade700),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.help_outline,
                                color: Colors.grey.shade600),
                              onPressed: () {
                                setState(() => mostrarAyuda = true);
                                Future.delayed(
                                  const Duration(seconds: 3),
                                  () => setState(() => mostrarAyuda = false),
                                );
                              },
                            ),
                          ],
                        ),
                        if (mostrarAyuda)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Cantidad de meses en que desea pagar la deuda',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildLabel('Monto Total de la Deuda'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          montoController,
                          _actualizarCuota,
                          keyboardType: TextInputType.number,
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
                          montoCanceladoController,
                          _actualizarCuota,
                          keyboardType: TextInputType.number,
                          prefixText: 'Q ',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el monto';
                            }
                            if (double.tryParse(value) == null || double.parse(value) < 0) {
                              return 'Monto inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 87, 156, 91),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade800.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUOTA ${periodo == 'Quincenal' ? 'QUINCENAL' : 'MENSUAL'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            periodo == 'Seleccione una opción'
                                ? 'Seleccione periodo'
                                : 'Valor estimado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                                'Q${cuotaCalculada.toStringAsFixed(2)}',
                                key: ValueKey<double>(cuotaCalculada),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 87, 156, 91), 
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B5E20),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    VoidCallback onChangedCallback, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => onChangedCallback(),
      validator: validator,
      enableInteractiveSelection: false,
      toolbarOptions: const ToolbarOptions(
        copy: false,
        paste: false,
        cut: false,
        selectAll: false,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
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
      value: periodo,
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
          periodo = value!;
          _actualizarCuota();
        });
      },
      validator: (value) {
        if (value == null || value == 'Seleccione una opción') {
          return 'Seleccione un periodo';
        }
        return null;
      },
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 0,
        ),
      ),
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      dropdownColor: const Color.fromARGB(255, 26, 30, 224),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down_rounded),
      isExpanded: true,
    );
  }
}