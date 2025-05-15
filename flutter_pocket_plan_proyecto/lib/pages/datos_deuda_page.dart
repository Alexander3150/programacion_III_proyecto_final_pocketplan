import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:intl/intl.dart';
import '../models/simulador_deuda.dart';

class DatosDeudaPage extends StatefulWidget {
  final SimuladorDeuda simulador;

  const DatosDeudaPage({super.key, required this.simulador});

  @override
  State<DatosDeudaPage> createState() => _DatosDeudaPageState();
}

class _DatosDeudaPageState extends State<DatosDeudaPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Detalles de la Deuda',
      body: DatosDeudaContent(simulador: widget.simulador),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class DatosDeudaContent extends StatefulWidget {
  final SimuladorDeuda simulador;

  const DatosDeudaContent({super.key, required this.simulador});

  @override
  State<DatosDeudaContent> createState() => _DatosDeudaContentState();
}

class _DatosDeudaContentState extends State<DatosDeudaContent> with TickerProviderStateMixin {
  final TextEditingController _montoController = TextEditingController();
  DateTime _fechaCuota = DateTime.now();
  String _metodoPago = 'Efectivo';
  List<Map<String, dynamic>> cuotasRegistradas = [];
  double progresoAcumulado = 0.0;
  bool camposBloqueados = false;
  bool mostrarCelebracion = false;
  late AnimationController _animationController;
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.simulador.montoCancelado.toStringAsFixed(2);
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animations = List.generate(15, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.05, 1, curve: Curves.easeOut),
        ),
      );
    });
  }

  void _mostrarCelebracion() {
    setState(() => mostrarCelebracion = true);
    _animationController.forward();
    Future.delayed(const Duration(seconds: 5), () {
      setState(() => mostrarCelebracion = false);
      _animationController.reset();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  double calcularProgreso(SimuladorDeuda simulador) {
    double totalPagado = cuotasRegistradas.fold(0.0, (sum, cuota) => sum + cuota['monto']);
    if (simulador.monto == 0) return 0.0;
    double progreso = totalPagado / simulador.monto;
    return progreso > 1.0 ? 1.0 : progreso;
  }

  Color obtenerColorBarra(double progreso) {
    if (progreso <= 0.25) return Colors.red;
    if (progreso <= 0.50) return Colors.orange;
    if (progreso <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  void _guardarCuota() {
    final montoPagado = double.tryParse(_montoController.text) ?? 0;
    if (montoPagado <= 0) return;

    final totalPagado = cuotasRegistradas.fold(0.0, (sum, cuota) => sum + cuota['monto']);
    final restante = widget.simulador.monto - totalPagado;

    if (montoPagado > restante) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No puedes ingresar una cuota mayor al restante: Q${restante.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final cuota = {
      'monto': montoPagado,
      'fecha': _fechaCuota,
      'metodo': _metodoPago,
    };

    setState(() {
      cuotasRegistradas.add(cuota);
      progresoAcumulado = calcularProgreso(widget.simulador);
      widget.simulador.progreso = progresoAcumulado;
      camposBloqueados = progresoAcumulado >= 1.0;
      
      if (camposBloqueados) {
        _mostrarCelebracion();
      }
    });
  }

  void _editarCuota(int index) {
    final cuota = cuotasRegistradas[index];
    _montoController.text = cuota['monto'].toString();
    _fechaCuota = cuota['fecha'];
    _metodoPago = cuota['metodo'];
    cuotasRegistradas.removeAt(index);
    setState(() {
      progresoAcumulado = calcularProgreso(widget.simulador);
      camposBloqueados = progresoAcumulado >= 1.0;
    });
  }

  void _eliminarCuota(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: AlertDialog(
          title: const Text('Confirmar eliminación', style: TextStyle(color: Color(0xFF2E7D32))),
          content: const Text('¿Estás seguro de que deseas eliminar esta cuota?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  cuotasRegistradas.removeAt(index);
                  progresoAcumulado = calcularProgreso(widget.simulador);
                  camposBloqueados = progresoAcumulado >= 1.0;
                });
              },
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final simulador = widget.simulador;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfo('Motivo de la Deuda:', simulador.motivo),
                      _buildInfo('Periodo de Pago:', simulador.periodo),
                      _buildInfo('Monto Total:', 'Q${simulador.monto.toStringAsFixed(2)}'),
                      _buildInfo('Monto Cancelado:', 'Q${simulador.montoCancelado.toStringAsFixed(2)}'),
                      _buildInfo('Fecha de Inicio:', _formatDate(simulador.fechaInicio)),
                      _buildInfo('Fecha de Fin:', _formatDate(simulador.fechaFin)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _montoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monto de la Cuota',
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          filled: true,
                          fillColor: camposBloqueados ? Colors.grey.shade200 : Colors.white,
                        ),
                        enableInteractiveSelection: false,
                        toolbarOptions: const ToolbarOptions(
                          copy: false,
                          paste: false,
                          cut: false,
                          selectAll: false,
                        ),
                        enabled: !camposBloqueados,
                        style: TextStyle(
                          color: camposBloqueados ? Colors.grey.shade600 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _metodoPago,
                              decoration: InputDecoration(
                                labelText: 'Método de Pago',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                filled: true,
                                fillColor: camposBloqueados ? Colors.grey.shade200 : Colors.white,
                              ),
                              items: ['Efectivo', 'Tarjeta']
                                  .map((value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: camposBloqueados ? Colors.grey.shade600 : Colors.black,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: camposBloqueados
                                  ? null
                                  : (value) => setState(() => _metodoPago = value!),
                              style: TextStyle(
                                color: camposBloqueados ? Colors.grey.shade600 : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: camposBloqueados ? Colors.grey.shade300 : const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.white),
                              onPressed: camposBloqueados
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _fechaCuota,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: Color(0xFF2E7D32),
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progresoAcumulado,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        obtenerColorBarra(progresoAcumulado),
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso: ${(progresoAcumulado * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (camposBloqueados)
                          Text(
                            '¡Deuda completada!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Guardar Cuota'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: camposBloqueados ? null : _guardarCuota,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services, size: 20),
                      label: const Text('Limpiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: camposBloqueados
                          ? null
                          : () {
                              _montoController.clear();
                              setState(() => _fechaCuota = DateTime.now());
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Cuotas Registradas:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cuotasRegistradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay cuotas registradas',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: cuotasRegistradas.length,
                        itemBuilder: (context, index) {
                          final cuota = cuotasRegistradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Q',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Q${cuota['monto'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              subtitle: Text(
                                '${_formatDate(cuota['fecha'])} - ${cuota['metodo']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFFF57C00)),
                                    onPressed: () => _editarCuota(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarCuota(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}