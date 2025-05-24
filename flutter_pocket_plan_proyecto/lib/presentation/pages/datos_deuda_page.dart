import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/cuota_pago_repository.dart';
import '../../data/models/repositories/simulador_deuda_repository.dart';
import '../../data/models/simulador_deuda.dart';
import '../../data/models/cuota_pago.dart';
import '../widgets/global_components.dart';
import '../providers/user_provider.dart';
import 'editar_simulador_de_deudas_page.dart'; // Importa tu pantalla de edición

class DatosDeudaPage extends StatefulWidget {
  final SimuladorDeuda simulador;

  const DatosDeudaPage({super.key, required this.simulador});

  @override
  State<DatosDeudaPage> createState() => _DatosDeudaPageState();
}

class _DatosDeudaPageState extends State<DatosDeudaPage>
    with TickerProviderStateMixin {
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

class _DatosDeudaContentState extends State<DatosDeudaContent>
    with TickerProviderStateMixin {
  final TextEditingController _montoController = TextEditingController();
  DateTime _fechaCuota = DateTime.now();

  List<CuotaPago> cuotasRegistradas = [];
  double progresoAcumulado = 0.0;
  bool camposBloqueados = false;
  bool mostrarAdvertenciaPlazo = false;
  int pagosPendientes = 0;
  int totalPagos = 0;
  bool plazoCumplidoYNoCancelada = false;
  late AnimationController _animationController;
  late SimuladorDeudaRepository _repoDeuda;
  late CuotaPagoRepository _repoCuota;
  late SimuladorDeuda _simuladorActual;
  int? _editingCuotaId;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _repoDeuda = SimuladorDeudaRepository();
    _repoCuota = CuotaPagoRepository();
    _simuladorActual = widget.simulador;
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarCuotasYActualizarPagoSugerido();
    _montoController.text = _simuladorActual.pagoSugerido.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Cálculo exacto de meses entre dos fechas (ignora días para ser exacto en meses)
  int mesesEntreFechas(DateTime inicio, DateTime fin) {
    int years = fin.year - inicio.year;
    int months = fin.month - inicio.month;
    int totalMonths = years * 12 + months;
    if (fin.day < inicio.day) totalMonths--;
    return totalMonths > 0 ? totalMonths : 0;
  }

  /// Carga cuotas y actualiza pagos pendientes/pago sugerido/advertencias
  Future<void> _cargarCuotasYActualizarPagoSugerido() async {
    if (_simuladorActual.id == null || _userId == null) return;
    final listaCuotas = await _repoCuota.getCuotasPorSimuladorId(
      _simuladorActual.id!,
      _userId!,
    );
    double pagado = listaCuotas.fold(0.0, (s, c) => s + c.monto);

    int plazo = mesesEntreFechas(
      _simuladorActual.fechaInicio,
      _simuladorActual.fechaFin,
    );
    if (plazo <= 0) plazo = 1;
    int pagosOriginales =
        _simuladorActual.periodo == "Quincenal" ? plazo * 2 : plazo;
    int pagosPend = pagosOriginales - listaCuotas.length;
    if (pagosPend < 0) pagosPend = 0;

    bool advertir = pagosPend == 0 && pagado < _simuladorActual.monto;
    bool plazoTerminadoYNoPagado =
        pagosPend == 0 && pagado < _simuladorActual.monto;

    double restante = (_simuladorActual.monto - pagado).clamp(
      0,
      double.infinity,
    );
    double pagoSugerido = pagosPend > 0 ? (restante / pagosPend) : restante;
    if (pagoSugerido < 0) pagoSugerido = 0;

    setState(() {
      cuotasRegistradas = listaCuotas;
      progresoAcumulado =
          _simuladorActual.monto == 0
              ? 0
              : (pagado / _simuladorActual.monto).clamp(0, 1.0);
      camposBloqueados = progresoAcumulado >= 1.0 || plazoTerminadoYNoPagado;
      _editingCuotaId = null;
      totalPagos = pagosOriginales;
      pagosPendientes = pagosPend;
      mostrarAdvertenciaPlazo = advertir;
      plazoCumplidoYNoCancelada = plazoTerminadoYNoPagado;
      _montoController.text = pagoSugerido.toStringAsFixed(2);
      _simuladorActual = _simuladorActual.copyWith(pagoSugerido: pagoSugerido);
    });

    await _repoDeuda.updateSimuladorDeuda(
      _simuladorActual.copyWith(
        montoCancelado: pagado,
        progreso: progresoAcumulado,
        pagoSugerido: pagoSugerido,
      ),
      _userId!,
    );
  }

  Future<void> _actualizarSimuladorDeuda() async {
    if (_userId == null) return;
    double pagado = cuotasRegistradas.fold(
      0.0,
      (sum, cuota) => sum + cuota.monto,
    );

    int plazo = mesesEntreFechas(
      _simuladorActual.fechaInicio,
      _simuladorActual.fechaFin,
    );
    if (plazo <= 0) plazo = 1;
    int pagosOriginales =
        _simuladorActual.periodo == "Quincenal" ? plazo * 2 : plazo;
    int pagosPend = pagosOriginales - cuotasRegistradas.length;
    if (pagosPend < 0) pagosPend = 0;
    bool advertir = pagosPend == 0 && pagado < _simuladorActual.monto;
    bool plazoTerminadoYNoPagado =
        pagosPend == 0 && pagado < _simuladorActual.monto;

    double restante = (_simuladorActual.monto - pagado).clamp(
      0,
      double.infinity,
    );
    double pagoSugerido = pagosPend > 0 ? (restante / pagosPend) : restante;
    double progreso =
        _simuladorActual.monto == 0
            ? 0
            : (pagado / _simuladorActual.monto).clamp(0.0, 1.0);

    final deudaActualizada = _simuladorActual.copyWith(
      montoCancelado: pagado,
      progreso: progreso,
      pagoSugerido: pagoSugerido,
    );
    await _repoDeuda.updateSimuladorDeuda(deudaActualizada, _userId!);
    setState(() {
      _simuladorActual = deudaActualizada;
      progresoAcumulado = progreso;
      camposBloqueados = progresoAcumulado >= 1.0 || plazoTerminadoYNoPagado;
      mostrarAdvertenciaPlazo = advertir;
      plazoCumplidoYNoCancelada = plazoTerminadoYNoPagado;
      _montoController.text = pagoSugerido.toStringAsFixed(2);
      _editingCuotaId = null;
    });
  }

  void _guardarCuota() async {
    if (_simuladorActual.id == null || _userId == null) return;
    final montoPagado = double.tryParse(_montoController.text) ?? 0;

    if (montoPagado <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (montoPagado > 999999.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto máximo permitido es Q999,999.99'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double pagadoPrevio = cuotasRegistradas
        .where((c) => c.id != _editingCuotaId)
        .fold(0.0, (sum, c) => sum + c.monto);

    double restante = _simuladorActual.monto - pagadoPrevio;
    if (montoPagado > restante) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes ingresar una cuota mayor al restante: Q${restante.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_editingCuotaId != null) {
      final cuotaEditada = cuotasRegistradas.firstWhere(
        (c) => c.id == _editingCuotaId,
      );
      final cuotaActualizada = cuotaEditada.copyWith(
        monto: montoPagado,
        fecha: _fechaCuota,
      );
      await _repoCuota.updateCuotaPago(cuotaActualizada, _userId!);
    } else {
      final cuota = CuotaPago(
        userId: _userId!,
        simuladorId: _simuladorActual.id!,
        monto: montoPagado,
        fecha: _fechaCuota,
      );
      await _repoCuota.insertCuotaPago(cuota, _userId!);
    }

    await _cargarCuotasYActualizarPagoSugerido();
    await _actualizarSimuladorDeuda();
    _limpiarCampos();
  }

  void _editarCuota(int index) {
    final cuota = cuotasRegistradas[index];
    setState(() {
      _montoController.text = cuota.monto.toStringAsFixed(2);
      _fechaCuota = cuota.fecha;
      _editingCuotaId = cuota.id;
    });
  }

  void _limpiarCampos() {
    setState(() {
      _montoController.text = _simuladorActual.pagoSugerido.toStringAsFixed(2);
      _fechaCuota = DateTime.now();
      _editingCuotaId = null;
    });
  }

  void _eliminarCuota(int index) async {
    final cuota = cuotasRegistradas[index];
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
            title: const Text(
              'Confirmar eliminación',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta cuota?',
            ),
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _repoCuota.deleteCuotaPago(cuota.id!, _userId!);
                  await _cargarCuotasYActualizarPagoSugerido();
                  await _actualizarSimuladorDeuda();
                  _limpiarCampos();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfo(String label, String value) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 100 : 120,
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
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Color obtenerColorBarra(double progreso) {
    if (progreso <= 0.25) return Colors.red;
    if (progreso <= 0.50) return Colors.orange;
    if (progreso <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final simulador = _simuladorActual;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 380 ? 4.0 : 16.0;
    final verticalPadding = screenWidth < 380 ? 4.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: SingleChildScrollView(
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
                    _buildInfo(
                      'Monto Total:',
                      'Q${simulador.monto.toStringAsFixed(2)}',
                    ),
                    _buildInfo(
                      'Monto Cancelado:',
                      'Q${simulador.montoCancelado.toStringAsFixed(2)}',
                    ),
                    _buildInfo(
                      'Fecha de Inicio:',
                      _formatDate(simulador.fechaInicio),
                    ),
                    _buildInfo(
                      'Fecha de Fin:',
                      _formatDate(simulador.fechaFin),
                    ),
                    _buildInfo('Pagos pendientes:', pagosPendientes.toString()),
                  ],
                ),
              ),
            ),
            if (mostrarAdvertenciaPlazo) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "El plazo de la deuda ya se cumplió y aún no lograste cancelarla.\n"
                            "Por favor, considera ampliar el plazo si no lograste cancelar la deuda en el tiempo establecido.",
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Editar Deuda"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditarSimuladorDeDeudasPage(
                                    simulador: _simuladorActual,
                                  ),
                            ),
                          );
                          if (updated == true &&
                              _simuladorActual.id != null &&
                              _userId != null) {
                            final nuevoSimulador =
                                await SimuladorDeudaRepository()
                                    .getSimuladorDeudaById(
                                      _simuladorActual.id!,
                                      _userId!,
                                    );
                            if (nuevoSimulador != null) {
                              setState(() {
                                _simuladorActual = nuevoSimulador;
                              });
                              await _cargarCuotasYActualizarPagoSugerido();
                              await _actualizarSimuladorDeuda();
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Pago sugerido: ',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Q${simulador.pagoSugerido.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
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
                        fillColor:
                            camposBloqueados
                                ? Colors.grey.shade200
                                : Colors.white,
                        counterText: '',
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
                        color:
                            camposBloqueados
                                ? Colors.grey.shade600
                                : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha de la Cuota: ${_formatDate(_fechaCuota)}',
                            style: TextStyle(
                              color:
                                  camposBloqueados
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color:
                                  camposBloqueados
                                      ? Colors.grey
                                      : const Color(0xFF2E7D32),
                            ),
                            onPressed:
                                camposBloqueados
                                    ? null
                                    : () async {
                                      final DateTime?
                                      picked = await showDatePicker(
                                        context: context,
                                        initialDate: _fechaCuota,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: Color(0xFF2E7D32),
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                              dialogBackgroundColor:
                                                  Colors.white,
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
                        ],
                      ),
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
                      if (camposBloqueados && !plazoCumplidoYNoCancelada)
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
                    label: Text(
                      _editingCuotaId != null
                          ? 'Guardar Edición'
                          : 'Guardar Cuota',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: camposBloqueados ? null : _limpiarCampos,
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
            cuotasRegistradas.isEmpty
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
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                          'Q${cuota.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(cuota.fecha),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFFF57C00),
                              ),
                              onPressed:
                                  camposBloqueados
                                      ? null
                                      : () => _editarCuota(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  camposBloqueados
                                      ? null
                                      : () => _eliminarCuota(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
