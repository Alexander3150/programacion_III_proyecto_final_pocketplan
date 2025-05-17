import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/widgets/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/registros_ie_page.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/movimiento_model.dart';
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2C3E50)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _selectedPeriod = 'Personalizado';
      });
    }
  }

  // Métodos para filtrar y calcular datos
  List<Movimiento> _filtrarMovimientos(String tipo, DateTimeRange range) {
    return _movimientos.where((mov) {
      return mov.tipo == tipo && 
             mov.fecha.isAfter(range.start.subtract(const Duration(days: 1))) && 
             mov.fecha.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  double _calcularTotal(String tipo, DateTimeRange range) {
    return _filtrarMovimientos(tipo, range)
      .fold(0, (sum, mov) => sum + mov.monto);
  }

  Map<String, double> _obtenerDistribucion(String tipo, DateTimeRange range) {
    final movs = _filtrarMovimientos(tipo, range);
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Presupuesto: Q. ${presupuesto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () async {
                  double? nuevoPresupuesto = await _mostrarDialogoPresupuesto(context, presupuesto);
                  if (nuevoPresupuesto != null) {
                    setState(() {
                      MovimientoRepository().presupuesto = nuevoPresupuesto;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _mostrarPresupuestoActual(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _tabController.index == 0 ? _ingresosColor : _egresosColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periodo: ${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<double?> _mostrarDialogoPresupuesto(BuildContext context, double actual) async {
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
                items: [
                  'Día', 'Semana', 'Mes', 'Año', 'Personalizado'
                ]
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
                      // Restablece fechas al periodo elegido
                      if (_selectedPeriod == 'Día') {
                        _dateRange = DateTimeRange(
                          start: DateTime.now(),
                          end: DateTime.now(),
                        );
                      } else if (_selectedPeriod == 'Semana') {
                        _dateRange = DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 6)),
                          end: DateTime.now(),
                        );
                      } else if (_selectedPeriod == 'Mes') {
                        _dateRange = DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        );
                      } else if (_selectedPeriod == 'Año') {
                        _dateRange = DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 365)),
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
        if (_selectedPeriod == 'Personalizado') // <-- SOLO muestra si está en personalizado
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
    final items = _obtenerDistribucion('ingreso', _dateRange).entries.map((entry) {
      final total = _calcularTotal('ingreso', _dateRange);
      final monto = (total * entry.value / 100).toStringAsFixed(2);
      
      return _ResumenItem(
        icon: _obtenerIconoPorEtiqueta(entry.key),
        label: entry.key,
        value: '${entry.value.toStringAsFixed(1)}%',
        amount: monto,
        color: _obtenerColorPorEtiqueta(entry.key),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (items.isNotEmpty) SizedBox(
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
          ) else const Padding(
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
    final items = _obtenerDistribucion('egreso', _dateRange).entries.map((entry) {
      final total = _calcularTotal('egreso', _dateRange);
      final monto = (total * entry.value / 100).toStringAsFixed(2);
      
      return _ResumenItem(
        icon: _obtenerIconoPorEtiqueta(entry.key),
        label: entry.key,
        value: '${entry.value.toStringAsFixed(1)}%',
        amount: monto,
        color: _obtenerColorPorEtiqueta(entry.key),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (items.isNotEmpty) SizedBox(
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
          ) else const Padding(
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

  const _ResumenItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
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
        trailing: Text(
          'Q$amount',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }
}
