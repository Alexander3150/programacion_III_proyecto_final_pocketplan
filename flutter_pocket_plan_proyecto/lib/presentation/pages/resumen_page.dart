import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/widgets/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/registros_ie_page.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/movimiento_model.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/card_manager.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/movimiento_repository.dart';

class ResumenScreen extends StatelessWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Resumen Financiero',
      body: const _ResumenTabs(),
      mostrarDrawer: true,
      navIndex: 0,
    );
  }
}

class _ResumenTabs extends StatefulWidget {
  const _ResumenTabs();

  @override
  State<_ResumenTabs> createState() => _ResumenTabsState();
}

class _ResumenTabsState extends State<_ResumenTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _ingresosColor = const Color(0xFF18BC9C);
  final Color _egresosColor = const Color(0xFFE74C3C);
  String _selectedPeriod = 'Mes';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  List<Movimiento> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarMovimientos();
  }

  void _cargarMovimientos() {
    setState(() {
      _movimientos = MovimientoRepository().movimientos;
    });
  }

  /// NUEVO: Devuelve lista de maps {'movimiento': Movimiento, 'index': int} ORDENADA DESCENDENTE
  List<Map<String, dynamic>> _filtrarMovimientosConIndice(
    String tipo,
    DateTimeRange range,
  ) {
    final lista = <Map<String, dynamic>>[];
    for (int i = 0; i < _movimientos.length; i++) {
      final mov = _movimientos[i];
      if (mov.tipo == tipo &&
          mov.fecha.isAfter(range.start.subtract(const Duration(days: 1))) &&
          mov.fecha.isBefore(range.end.add(const Duration(days: 1)))) {
        lista.add({'movimiento': mov, 'index': i});
      }
    }
    lista.sort(
      (a, b) => (b['movimiento'] as Movimiento).fecha.compareTo(
        (a['movimiento'] as Movimiento).fecha,
      ),
    );
    return lista;
  }

  double _calcularTotal(String tipo, DateTimeRange range) {
    return _filtrarMovimientosConIndice(
      tipo,
      range,
    ).fold(0, (sum, entry) => sum + (entry['movimiento'] as Movimiento).monto);
  }

  Map<String, double> _obtenerDistribucion(String tipo, DateTimeRange range) {
    final movs =
        _filtrarMovimientosConIndice(
          tipo,
          range,
        ).map((e) => e['movimiento'] as Movimiento).toList();
    final total = _calcularTotal(tipo, range);

    if (total == 0) return {};

    return movs.fold<Map<String, double>>({}, (map, mov) {
      map[mov.etiqueta] = (map[mov.etiqueta] ?? 0) + (mov.monto / total * 100);
      return map;
    });
  }

  String _mostrarPresupuestoActual() {
    final totalIngresos = _calcularTotal('ingreso', _dateRange);
    final totalEgresos = _calcularTotal('egreso', _dateRange);
    final presupuesto = MovimientoRepository().presupuesto;
    final restante = presupuesto + totalIngresos - totalEgresos;

    return 'Presupuesto restante: Q. ${restante.toStringAsFixed(2)}';
  }

  Color _obtenerColorPorEtiqueta(String etiqueta) {
    const colores = {
      'Salario': Color(0xFF18BC9C),
      'Freelance': Color(0xFF2ECC71),
      'Inversiones': Color(0xFF3498DB),
      'Comida': Color(0xFFE74C3C),
      'Transporte': Color(0xFFF39C12),
      'Renta': Color(0xFF9B59B6),
      'Regalo': Color(0xFF16A085),
      'Entretenimiento': Color(0xFF9C27B0),
      'Servicios': Color(0xFF00BFAE),
      'Otros': Color(0xFF607D8B),
    };
    return colores[etiqueta] ?? Colors.grey;
  }

  IconData _obtenerIconoPorEtiqueta(String etiqueta) {
    const iconos = {
      'Salario': Icons.monetization_on,
      'Freelance': Icons.work_outline,
      'Inversiones': Icons.trending_up,
      'Comida': Icons.restaurant,
      'Transporte': Icons.directions_car,
      'Renta': Icons.home_work_outlined,
      'Regalo': Icons.card_giftcard,
      'Entretenimiento': Icons.movie,
      'Servicios': Icons.miscellaneous_services,
      'Otros': Icons.category,
    };
    return iconos[etiqueta] ?? Icons.category;
  }

  List<PieChartSectionData> _buildIngresosChartSections() {
    final distribucion = _obtenerDistribucion('ingreso', _dateRange);

    return distribucion.entries.map((entry) {
      final color = _obtenerColorPorEtiqueta(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _buildEgresosChartSections() {
    final distribucion = _obtenerDistribucion('egreso', _dateRange);

    return distribucion.entries.map((entry) {
      final color = _obtenerColorPorEtiqueta(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Future<void> _editarMovimiento(
    BuildContext context,
    Movimiento mov,
    int index,
  ) async {
    final montoController = TextEditingController(text: mov.monto.toString());
    final conceptoController = TextEditingController(text: mov.concepto);
    DateTime fechaSeleccionada = mov.fecha;
    String etiquetaSeleccionada = mov.etiqueta;

    final List<String> etiquetas =
        mov.tipo == 'ingreso'
            ? ['Salario', 'Freelance', 'Inversiones', 'Regalo', 'Otros']
            : [
              'Comida',
              'Transporte',
              'Entretenimiento',
              'Servicios',
              'Renta',
              'Otros',
            ];

    final editado = await showDialog<Movimiento>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateDialog) => AlertDialog(
                  title: const Text('Editar Movimiento'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: montoController,
                          decoration: const InputDecoration(labelText: 'Monto'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: conceptoController,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: etiquetaSeleccionada,
                          items:
                              etiquetas
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(
                                () => etiquetaSeleccionada = value,
                              );
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Etiqueta',
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final nuevaFecha = await showDatePicker(
                              context: ctx,
                              initialDate: fechaSeleccionada,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (nuevaFecha != null) {
                              setStateDialog(
                                () => fechaSeleccionada = nuevaFecha,
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (mov.tipo == 'egreso' && mov.metodoPago != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Método de pago: ${mov.metodoPago}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (mov.tarjetaId != null &&
                                      (mov.metodoPago == 'Tarjeta Crédito' ||
                                          mov.metodoPago == 'Tarjeta Débito'))
                                    Text(
                                      'Tarjeta: ${_aliasDeTarjeta(mov)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Guardar'),
                      onPressed: () {
                        final nuevoMonto =
                            double.tryParse(montoController.text) ?? mov.monto;
                        final nuevoConcepto =
                            conceptoController.text.isNotEmpty
                                ? conceptoController.text
                                : mov.concepto;

                        // --- VALIDACIÓN DEL LÍMITE DE TARJETA DE CRÉDITO AL EDITAR ---
                        if (mov.tipo == 'egreso' &&
                            mov.metodoPago == 'Tarjeta Crédito' &&
                            mov.tarjetaId != null) {
                          final tarjeta = CardManager().creditCards.firstWhere(
                            (c) => c.id == mov.tarjetaId,
                            orElse:
                                () =>
                                    CardManager().creditCards.isNotEmpty
                                        ? CardManager().creditCards.first
                                        : throw Exception(
                                          'No CreditCard found',
                                        ),
                          );

                          if (tarjeta != null) {
                            // Sumar egresos con esa tarjeta (excepto el actual movimiento)
                            final egresosConEsaTarjeta = _movimientos.where(
                              (m) =>
                                  m.tipo == 'egreso' &&
                                  m.metodoPago == 'Tarjeta Crédito' &&
                                  m.tarjetaId == mov.tarjetaId &&
                                  m != mov,
                            );

                            double sumaOtrosEgresos = egresosConEsaTarjeta.fold(
                              0.0,
                              (sum, m) => sum + m.monto,
                            );

                            double totalConEdicion =
                                sumaOtrosEgresos + nuevoMonto;

                            if (totalConEdicion > tarjeta.limite) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'El monto excede el límite de la tarjeta.\nLímite: Q${tarjeta.limite.toStringAsFixed(2)}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // NO guarda, se queda en el diálogo
                            }
                          }
                        }

                        final movimientoActualizado = Movimiento(
                          tipo: mov.tipo,
                          fecha: fechaSeleccionada,
                          monto: nuevoMonto,
                          concepto: nuevoConcepto,
                          etiqueta: etiquetaSeleccionada,
                          metodoPago: mov.metodoPago,
                          tarjetaId: mov.tarjetaId,
                          tipoTarjeta: mov.tipoTarjeta,
                          opcionPago: mov.opcionPago,
                          cuotas: mov.cuotas,
                        );
                        Navigator.of(ctx).pop(movimientoActualizado);
                      },
                    ),
                  ],
                ),
          ),
    );

    if (editado != null) {
      MovimientoRepository().actualizarMovimiento(index, editado);
      setState(() => _cargarMovimientos());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento editado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _eliminarMovimiento(
    BuildContext context,
    Movimiento mov,
    int index,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Movimiento'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este movimiento? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      MovimientoRepository().eliminarMovimiento(index);
      setState(() => _cargarMovimientos());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento eliminado'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _aliasDeTarjeta(Movimiento mov) {
    if (mov.metodoPago == 'Tarjeta Crédito') {
      final tarjeta = CardManager().creditCards.firstWhere(
        (c) => c.id == mov.tarjetaId,
        orElse: () => null as dynamic,
      );
      return tarjeta != null ? '${tarjeta.banco} - ${tarjeta.alias}' : '';
    } else if (mov.metodoPago == 'Tarjeta Débito') {
      final tarjeta = CardManager().debitCards.firstWhere(
        (c) => c.id == mov.tarjetaId,
        orElse: () => null as dynamic,
      );
      return tarjeta != null ? '${tarjeta.banco} - ${tarjeta.alias}' : '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBudgetDisplay(context),
        _buildPeriodSelector(context),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildIngresosTab(context), _buildEgresosTab(context)],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetDisplay(BuildContext context) {
    final presupuesto = MovimientoRepository().presupuesto;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF18BC9C), Color(0xFF2980B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF18BC9C).withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(width: 12),
              Text(
                "PRESUPUESTO",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: () async {
                  double? nuevoPresupuesto = await _mostrarDialogoPresupuesto(
                    context,
                    presupuesto,
                  );
                  if (nuevoPresupuesto != null) {
                    setState(() {
                      MovimientoRepository().presupuesto = nuevoPresupuesto;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Q. ${presupuesto.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.savings, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Text(
                _mostrarPresupuestoActual(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Periodo: ${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
                style: const TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<double?> _mostrarDialogoPresupuesto(
    BuildContext context,
    double actual,
  ) async {
    final controlador = TextEditingController(text: actual.toString());
    double? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar presupuesto'),
          content: TextField(
            controller: controlador,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Presupuesto'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                final valor = double.tryParse(controlador.text);
                if (valor != null && valor >= 0) {
                  result = valor;
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
    return result;
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items:
                      ['Día', 'Semana', 'Mes', 'Año', 'Personalizado']
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(period),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == 'Personalizado') {
                      _selectDateRange(context);
                    } else {
                      setState(() {
                        _selectedPeriod = value!;
                        if (_selectedPeriod == 'Día') {
                          _dateRange = DateTimeRange(
                            start: DateTime.now(),
                            end: DateTime.now(),
                          );
                        } else if (_selectedPeriod == 'Semana') {
                          _dateRange = DateTimeRange(
                            start: DateTime.now().subtract(
                              const Duration(days: 6),
                            ),
                            end: DateTime.now(),
                          );
                        } else if (_selectedPeriod == 'Mes') {
                          _dateRange = DateTimeRange(
                            start: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            end: DateTime.now(),
                          );
                        } else if (_selectedPeriod == 'Año') {
                          _dateRange = DateTimeRange(
                            start: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            end: DateTime.now(),
                          );
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          if (_selectedPeriod == 'Personalizado')
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent),
              tooltip: "Limpiar filtro de fechas",
              onPressed: () {
                setState(() {
                  _selectedPeriod = 'Mes';
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  );
                });
              },
            ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () async {
              final nuevoMovimiento = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroMovimientoScreen(),
                ),
              );
              if (nuevoMovimiento != null && nuevoMovimiento is Movimiento) {
                _cargarMovimientos();
              }
            },
            backgroundColor:
                _tabController.index == 0 ? _ingresosColor : _egresosColor,
            mini: true,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Personalizado';
        _dateRange = picked;
      });
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3,
            color: _tabController.index == 0 ? _ingresosColor : _egresosColor,
          ),
          insets: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.1,
          ),
        ),
        labelColor: _tabController.index == 0 ? _ingresosColor : _egresosColor,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [Tab(text: 'INGRESOS'), Tab(text: 'EGRESOS')],
        onTap: (index) => setState(() {}),
      ),
    );
  }

  Widget _buildIngresosTab(BuildContext context) {
    final movimientosFiltrados = _filtrarMovimientosConIndice(
      'ingreso',
      _dateRange,
    );

    final items =
        movimientosFiltrados.map((entry) {
          final mov = entry['movimiento'] as Movimiento;
          final indexGlobal = entry['index'] as int;
          final total = _calcularTotal('ingreso', _dateRange);
          final porcentaje = total > 0 ? (mov.monto / total) * 100 : 0;
          return _ResumenItem(
            icon: _obtenerIconoPorEtiqueta(mov.etiqueta),
            label: mov.etiqueta,
            value: '${porcentaje.toStringAsFixed(1)}%',
            amount: mov.monto.toStringAsFixed(2),
            color: _obtenerColorPorEtiqueta(mov.etiqueta),
            onEdit: () => _editarMovimiento(context, mov, indexGlobal),
            onDelete: () => _eliminarMovimiento(context, mov, indexGlobal),
          );
        }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (items.isNotEmpty)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildIngresosChartSections(),
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No hay ingresos registrados en este periodo'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ResumenList(items: items),
          ),
        ],
      ),
    );
  }

  Widget _buildEgresosTab(BuildContext context) {
    final movimientosFiltrados = _filtrarMovimientosConIndice(
      'egreso',
      _dateRange,
    );

    final items =
        movimientosFiltrados.map((entry) {
          final mov = entry['movimiento'] as Movimiento;
          final indexGlobal = entry['index'] as int;
          final total = _calcularTotal('egreso', _dateRange);
          final porcentaje = total > 0 ? (mov.monto / total) * 100 : 0;
          return _ResumenItem(
            icon: _obtenerIconoPorEtiqueta(mov.etiqueta),
            label: mov.etiqueta,
            value: '${porcentaje.toStringAsFixed(1)}%',
            amount: mov.monto.toStringAsFixed(2),
            color: _obtenerColorPorEtiqueta(mov.etiqueta),
            onEdit: () => _editarMovimiento(context, mov, indexGlobal),
            onDelete: () => _eliminarMovimiento(context, mov, indexGlobal),
          );
        }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (items.isNotEmpty)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildEgresosChartSections(),
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No hay egresos registrados en este periodo'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ResumenList(items: items),
          ),
        ],
      ),
    );
  }
}

class _ResumenList extends StatelessWidget {
  final List<_ResumenItem> items;
  const _ResumenList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String amount;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ResumenItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(value),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Q$amount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C3E50),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Eliminar',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
