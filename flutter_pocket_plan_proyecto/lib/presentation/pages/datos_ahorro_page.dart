import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/cuota_ahorro_repository.dart';
import '../../data/models/repositories/simulador_ahorro_repository.dart';
import '../../data/models/simulador_ahorro.dart';
import '../../data/models/cuota_ahorro.dart';
import '../widgets/global_components.dart';
import '../providers/user_provider.dart';
import 'editar_simulador_de_ahorros_page.dart';

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
  static const Color cardBackground = Color(0xFFF1F8E9);
  static const Color dividerColor = Color(0xFFC8E6C9);
  static const Color red = Colors.red;
  static const Color yellow = Colors.amber;
  static const Color blue = Colors.lightBlue;
  static const Color green = Colors.green;
}

class DatosAhorroPage extends StatefulWidget {
  final SimuladorAhorro simulador;

  const DatosAhorroPage({super.key, required this.simulador});

  @override
  State<DatosAhorroPage> createState() => _DatosAhorroPageState();
}

class _DatosAhorroPageState extends State<DatosAhorroPage> {
  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Detalles del Ahorro',
      body: DatosAhorroContent(simulador: widget.simulador),
      mostrarDrawer: true,
      mostrarBotonHome: true,
      navIndex: 0,
    );
  }
}

class DatosAhorroContent extends StatefulWidget {
  final SimuladorAhorro simulador;

  const DatosAhorroContent({super.key, required this.simulador});

  @override
  State<DatosAhorroContent> createState() => _DatosAhorroContentState();
}

class _DatosAhorroContentState extends State<DatosAhorroContent> {
  final TextEditingController _montoController = TextEditingController();
  DateTime _fechaCuota = DateTime.now();
  List<CuotaAhorro> cuotasRegistradas = [];
  double progresoAcumulado = 0.0;
  double montoAhorrado = 0.0;
  bool camposBloqueados = false;
  int? _editingCuotaId;

  late CuotaAhorroRepository _cuotaRepo;
  late SimuladorAhorroRepository _simuladorRepo;
  late SimuladorAhorro _simuladorActual;
  int? _userId;

  int totalPagos = 0;
  int totalPagosRestantes = 0;
  bool mostrarAdvertenciaPlazo = false;
  bool plazoCumplidoYNoAlcanzado = false;

  @override
  void initState() {
    super.initState();
    _cuotaRepo = CuotaAhorroRepository();
    _simuladorRepo = SimuladorAhorroRepository();
    _simuladorActual = widget.simulador;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarCuotasYActualizarSugerida();
    _montoController.text = _simuladorActual.cuotaSugerida.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// --- Cálculo exacto de meses entre dos fechas (como en la pantalla de deudas)
  int mesesEntreFechas(DateTime inicio, DateTime fin) {
    int years = fin.year - inicio.year;
    int months = fin.month - inicio.month;
    int totalMonths = years * 12 + months;
    if (fin.day < inicio.day) totalMonths--;
    return totalMonths > 0 ? totalMonths : 0;
  }

  /// --- Carga cuotas y calcula el total de pagos y pagos restantes usando cálculo exacto de meses
  Future<void> _cargarCuotasYActualizarSugerida() async {
    final listaCuotas = await _cuotaRepo.getCuotasPorSimuladorId(
      _simuladorActual.id!,
      _userId!,
    );
    double ahorrado = listaCuotas.fold(0.0, (s, c) => s + c.monto);

    int plazo = mesesEntreFechas(
      _simuladorActual.fechaInicio,
      _simuladorActual.fechaFin,
    );
    if (plazo <= 0) plazo = 1;
    int pagosOriginales =
        _simuladorActual.periodo == "Quincenal" ? plazo * 2 : plazo;

    int pagosRestantes = pagosOriginales - listaCuotas.length;
    if (pagosRestantes < 0) pagosRestantes = 0;

    bool advertir = pagosRestantes == 0 && ahorrado < _simuladorActual.monto;
    bool plazoTerminadoYNoAlcanzado = advertir;

    double restante = (_simuladorActual.monto - ahorrado).clamp(
      0,
      double.infinity,
    );
    double cuotaSugerida =
        pagosRestantes > 0 ? (restante / pagosRestantes) : restante;
    if (cuotaSugerida < 0) cuotaSugerida = 0;

    setState(() {
      cuotasRegistradas = listaCuotas;
      progresoAcumulado =
          _simuladorActual.monto == 0
              ? 0
              : (ahorrado / _simuladorActual.monto).clamp(0, 1.0);
      montoAhorrado = ahorrado;
      camposBloqueados = progresoAcumulado >= 1.0 || plazoTerminadoYNoAlcanzado;
      _editingCuotaId = null;
      totalPagos = pagosOriginales;
      totalPagosRestantes = pagosRestantes;
      mostrarAdvertenciaPlazo = advertir;
      plazoCumplidoYNoAlcanzado = plazoTerminadoYNoAlcanzado;
      _montoController.text = cuotaSugerida.toStringAsFixed(2);
      _simuladorActual = _simuladorActual.copyWith(
        cuotaSugerida: cuotaSugerida,
      );
    });

    // Actualiza BD para persistir sugerido y progreso
    await _simuladorRepo.updateSimuladorAhorro(
      _simuladorActual.copyWith(
        progreso: progresoAcumulado,
        cuotaSugerida: cuotaSugerida,
      ),
      _userId!,
    );
  }

  void _guardarCuota() async {
    if (_simuladorActual.id == null || _userId == null) return;
    final monto = double.tryParse(_montoController.text) ?? 0;

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a cero'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (monto > 999999.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto máximo permitido es Q999,999.99'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    double ahorradoPrevio = cuotasRegistradas
        .where((c) => c.id != _editingCuotaId)
        .fold(0.0, (sum, c) => sum + c.monto);
    double restante = _simuladorActual.monto - ahorradoPrevio;

    final montoRounded = double.parse(monto.toStringAsFixed(2));
    final restanteRounded = double.parse(restante.toStringAsFixed(2));

    if (montoRounded > restanteRounded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No puedes ingresar una cuota mayor al restante: Q${restanteRounded.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_editingCuotaId != null) {
      final cuotaEditada = cuotasRegistradas.firstWhere(
        (c) => c.id == _editingCuotaId,
      );
      final cuotaActualizada = cuotaEditada.copyWith(
        monto: monto,
        fecha: _fechaCuota,
      );
      await _cuotaRepo.updateCuotaAhorro(cuotaActualizada);
    } else {
      final cuota = CuotaAhorro(
        userId: _userId!,
        simuladorId: _simuladorActual.id!,
        monto: monto,
        fecha: _fechaCuota,
      );
      await _cuotaRepo.insertCuotaAhorro(cuota);
      setState(() {
        if (totalPagosRestantes > 0) totalPagosRestantes--;
      });
    }

    await _cargarCuotasYActualizarSugerida();
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
      _montoController.text = _simuladorActual.cuotaSugerida.toStringAsFixed(2);
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
              style: TextStyle(color: AppColors.primary),
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
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cuotaRepo.deleteCuotaAhorro(cuota.id!, _userId!);
                  await _cargarCuotasYActualizarSugerida();
                  _limpiarCampos();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color obtenerColorBarra(double progreso) {
    if (progreso <= 0.25) return AppColors.red;
    if (progreso <= 0.50) return AppColors.yellow;
    if (progreso <= 0.75) return AppColors.blue;
    return AppColors.green;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertenciaYBotonEditar(BuildContext context) {
    return Container(
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
              const Icon(Icons.warning, color: Colors.orange, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "El plazo del ahorro ya se cumplió y aún no lograste tu meta. "
                  "Por favor, considera ampliar el plazo si no lograste ahorrar lo suficiente.",
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
              label: const Text("Editar Ahorro"),
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
                        (context) => EditarSimuladorDeAhorrosPage(
                          simulador: _simuladorActual,
                        ),
                  ),
                );
                if (updated == true &&
                    _simuladorActual.id != null &&
                    _userId != null) {
                  final nuevoSimulador = await SimuladorAhorroRepository()
                      .getSimuladorAhorroById(_simuladorActual.id!, _userId!);
                  if (nuevoSimulador != null) {
                    setState(() {
                      _simuladorActual = nuevoSimulador;
                    });
                    await _cargarCuotasYActualizarSugerida();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final simulador = _simuladorActual;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general del ahorro
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardBackground,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del Plan de Ahorro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Objetivo del Ahorro:', simulador.objetivo),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow('Periodo de Ahorro:', simulador.periodo),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Monto Total a Ahorrar:',
                      'Q${simulador.monto.toStringAsFixed(2)}',
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Monto Ahorrado hasta ahora:',
                      'Q${montoAhorrado.toStringAsFixed(2)}',
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Fecha de Inicio:',
                      _formatDate(simulador.fechaInicio),
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Fecha de Fin:',
                      _formatDate(simulador.fechaFin),
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Pagos pendientes:',
                      totalPagosRestantes.toString(),
                    ),
                    const Divider(color: AppColors.dividerColor),
                    _buildInfoRow(
                      'Monto Sugerido por Periodo:',
                      'Q${simulador.cuotaSugerida.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            if (mostrarAdvertenciaPlazo) ...[
              const SizedBox(height: 18),
              _buildAdvertenciaYBotonEditar(context),
            ],
            const SizedBox(height: 24),
            // Sección para agregar cuotas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar Nueva Cuota',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        labelStyle: const TextStyle(color: AppColors.textDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.textField,
                        prefixIcon: const Icon(
                          Icons.money,
                          color: AppColors.primary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      enabled: !camposBloqueados,
                      buildCounter:
                          (
                            context, {
                            required int currentLength,
                            required bool isFocused,
                            int? maxLength,
                          }) => null,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha de Ahorro: ${_formatDate(_fechaCuota)}',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
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
                                                    primary: AppColors.primary,
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
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progreso del Ahorro:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progresoAcumulado,
                            backgroundColor: AppColors.accent.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              obtenerColorBarra(progresoAcumulado),
                            ),
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso: ${(progresoAcumulado * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Q${(simulador.monto * progresoAcumulado).toStringAsFixed(2)} de Q${simulador.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (progresoAcumulado >= 1.0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success,
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '¡Felicidades! Has completado tu meta de ahorro.',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _editingCuotaId != null
                                      ? 'Guardar Edición'
                                      : 'Guardar Cuota',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onPressed:
                                    camposBloqueados ? null : _guardarCuota,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.cleaning_services,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'Limpiar',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                onPressed:
                                    camposBloqueados ? null : _limpiarCampos,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 24),
            // Cuotas registradas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cuotas Registradas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (cuotasRegistradas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No hay cuotas registradas aún',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: cuotasRegistradas.length,
                          separatorBuilder:
                              (context, index) => const Divider(
                                color: AppColors.dividerColor,
                                height: 1,
                              ),
                          itemBuilder: (context, index) {
                            final cuota = cuotasRegistradas[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Q${cuota.monto.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Fecha: ${_formatDate(cuota.fecha)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                    ),
                                    onPressed:
                                        camposBloqueados
                                            ? null
                                            : () => _editarCuota(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                    ),
                                    onPressed:
                                        camposBloqueados
                                            ? null
                                            : () => _eliminarCuota(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
