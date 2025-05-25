import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/models/repositories/movimiento_repository.dart';
import '../providers/user_provider.dart';

class GraficosScreen extends StatefulWidget {
  const GraficosScreen({super.key});

  @override
  State<GraficosScreen> createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTipo = 'egreso';
  String _selectedPeriod = 'Mes';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  List<Movimiento> _movimientos = [];
  String? _selectedEtiqueta;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarMovimientos());
  }

  Future<void> _cargarMovimientos() async {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final user = userProvider.usuario;
    if (user != null) {
      final movimientos = await MovimientoRepository().getMovimientosByUser(
        user.id!,
      );
      setState(() => _movimientos = movimientos);
    }
  }

  List<Movimiento> get movimientosFiltrados {
    return _movimientos.where((m) {
      final tipoOk = m.tipo == _selectedTipo;
      final fechaOk =
          m.fecha.isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
          m.fecha.isBefore(_dateRange.end.add(const Duration(days: 1)));
      final etiquetaOk =
          _selectedEtiqueta == null || m.etiqueta == _selectedEtiqueta;
      return tipoOk && fechaOk && etiquetaOk;
    }).toList();
  }

  Map<String, double> get distribucion {
    final total = movimientosFiltrados.fold(0.0, (sum, m) => sum + m.monto);
    final map = <String, double>{};
    for (final m in movimientosFiltrados) {
      map[m.etiqueta] = (map[m.etiqueta] ?? 0) + m.monto;
    }
    if (total == 0) return {};
    return map.map((k, v) => MapEntry(k, v / total * 100));
  }

  double get totalTipo =>
      movimientosFiltrados.fold(0.0, (sum, m) => sum + m.monto);

  Color obtenerColorPorEtiqueta(String etiqueta) {
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

  IconData obtenerIconoPorEtiqueta(String etiqueta) {
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

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF18BC9C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Personalizado';
        _dateRange = picked;
      });
    }
  }

  void _limpiarFiltroEtiqueta() {
    setState(() => _selectedEtiqueta = null);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Análisis Financiero',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 25,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF18BC9C),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF18BC9C),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Gráfico de Pastel', icon: Icon(Icons.pie_chart)),
                  Tab(text: 'Gráfico de Barras', icon: Icon(Icons.bar_chart)),
                ],
              ),
              Container(height: 1, color: Colors.grey.withOpacity(0.1)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros superiores
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: ToggleButtons(
                            borderRadius: BorderRadius.circular(12),
                            borderColor: Colors.transparent,
                            selectedBorderColor: Colors.transparent,
                            fillColor: const Color(
                              0xFF18BC9C,
                            ).withOpacity(0.15),
                            selectedColor: const Color(0xFF18BC9C),
                            color: Colors.grey[700],
                            isSelected: [
                              _selectedTipo == 'ingreso',
                              _selectedTipo == 'egreso',
                            ],
                            onPressed:
                                (i) => setState(() {
                                  _selectedTipo = i == 0 ? 'ingreso' : 'egreso';
                                  _selectedEtiqueta = null;
                                }),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_downward, size: 18),
                                    SizedBox(width: 6),
                                    Text('Ingresos'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_upward, size: 18),
                                    SizedBox(width: 6),
                                    Text('Gastos'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF2C3E50),
                              ),
                              items:
                                  [
                                        'Día',
                                        'Semana',
                                        'Mes',
                                        'Año',
                                        'Personalizado',
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(e),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v == 'Personalizado') {
                                  _selectDateRange(context);
                                } else {
                                  setState(() {
                                    _selectedPeriod = v!;
                                    if (v == 'Día') {
                                      _dateRange = DateTimeRange(
                                        start: DateTime.now(),
                                        end: DateTime.now(),
                                      );
                                    } else if (v == 'Semana') {
                                      _dateRange = DateTimeRange(
                                        start: DateTime.now().subtract(
                                          const Duration(days: 6),
                                        ),
                                        end: DateTime.now(),
                                      );
                                    } else if (v == 'Mes') {
                                      _dateRange = DateTimeRange(
                                        start: DateTime.now().subtract(
                                          const Duration(days: 30),
                                        ),
                                        end: DateTime.now(),
                                      );
                                    } else if (v == 'Año') {
                                      _dateRange = DateTimeRange(
                                        start: DateTime.now().subtract(
                                          const Duration(days: 365),
                                        ),
                                        end: DateTime.now(),
                                      );
                                    }
                                    _selectedEtiqueta = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 18),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedEtiqueta != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          backgroundColor: obtenerColorPorEtiqueta(
                            _selectedEtiqueta!,
                          ).withOpacity(0.13),
                          label: Row(
                            children: [
                              Icon(
                                obtenerIconoPorEtiqueta(_selectedEtiqueta!),
                                color: obtenerColorPorEtiqueta(
                                  _selectedEtiqueta!,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedEtiqueta!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          onDeleted: _limpiarFiltroEtiqueta,
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Total
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _selectedTipo == 'egreso'
                        ? const Color(0xFFE74C3C).withOpacity(0.05)
                        : const Color(0xFF18BC9C).withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _selectedTipo == 'egreso'
                        ? 'GASTOS TOTALES'
                        : 'INGRESOS TOTALES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Q${totalTipo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color:
                          _selectedTipo == 'egreso'
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFF18BC9C),
                    ),
                  ),
                ],
              ),
            ),
            // Gráficos y lista
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGraficosYDetalle(
                    isTablet: isTablet,
                    enablePieSelect: true,
                  ),
                  _buildGraficosYDetalle(
                    isTablet: isTablet,
                    enablePieSelect: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficosYDetalle({
    bool isTablet = false,
    required bool enablePieSelect,
  }) {
    final data = distribucion;
    final movimientos = movimientosFiltrados;
    final agrupados = <String, List<Movimiento>>{};
    for (final mov in movimientos) {
      agrupados.putIfAbsent(mov.etiqueta, () => []).add(mov);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 0),
      child: Column(
        children: [
          // Gráfico
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            height: isTablet ? 300 : 220,
            child:
                data.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.insert_chart_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay datos para mostrar',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : enablePieSelect
                    ? _buildPieChart(isTablet: isTablet)
                    : _buildBarChart(isTablet: isTablet),
          ),
          // Lista de movimientos
          Expanded(
            child:
                agrupados.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay movimientos para mostrar',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: agrupados.entries.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = agrupados.entries.elementAt(index);
                        final etiqueta = entry.key;
                        final listaMov = entry.value;
                        final color = obtenerColorPorEtiqueta(etiqueta);
                        final icono = obtenerIconoPorEtiqueta(etiqueta);
                        final montoTotal = listaMov.fold<double>(
                          0,
                          (s, m) => s + m.monto,
                        );
                        final porcentaje =
                            totalTipo > 0
                                ? (montoTotal / totalTipo) * 100
                                : 0.0;

                        return _buildCategoryCard(
                          color: color,
                          icon: icono,
                          label: etiqueta,
                          percentage: porcentaje,
                          amount: montoTotal,
                          movements: listaMov,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required Color color,
    required IconData icon,
    required String label,
    required double percentage,
    required double amount,
    required List<Movimiento> movements,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: percentage * 2,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}% del total',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Q${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${movements.length} ${movements.length == 1 ? 'movimiento' : 'movimientos'}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        children:
            movements.map((mov) => _buildMovementTile(mov, color)).toList(),
      ),
    );
  }

  Widget _buildPieChart({bool isTablet = false}) {
    final data = distribucion;
    if (data.isEmpty) return const SizedBox();
    final sections =
        data.entries.map((entry) {
          final color = obtenerColorPorEtiqueta(entry.key);
          return PieChartSectionData(
            value: entry.value,
            title: '${entry.value.toStringAsFixed(1)}%',
            color: color,
            radius: isTablet ? 92 : 64,
            titleStyle: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                obtenerIconoPorEtiqueta(entry.key),
                color: Colors.white,
                size: isTablet ? 24 : 18,
              ),
            ),
            badgePositionPercentageOffset: .92,
          );
        }).toList();
    final dataKeys = data.keys.toList();
    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 1,
        centerSpaceRadius: isTablet ? 60 : 40,
        pieTouchData: PieTouchData(
          touchCallback: (event, resp) {
            if (resp != null && resp.touchedSection != null) {
              final idx = resp.touchedSection!.touchedSectionIndex;
              if (idx >= 0 && idx < dataKeys.length) {
                setState(() {
                  _selectedEtiqueta = dataKeys[idx];
                });
              }
            }
          },
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 600),
      swapAnimationCurve: Curves.easeInOutCubic,
    );
  }

  Widget _buildBarChart({bool isTablet = false}) {
    final data = distribucion;
    if (data.isEmpty) return const SizedBox();
    final labels = data.keys.toList();

    final barWidth = isTablet ? 34.0 : 24.0;
    final chartWidth = (barWidth + 22) * labels.length + 40;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: isTablet ? 290 : 200,
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: isTablet ? 45 : 38,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(left: isTablet ? 8 : 4),
                      child: Text(
                        '${value.toInt()}%',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: isTablet ? 40 : 32, // Reducido para solo iconos
                  getTitlesWidget: (double value, _) {
                    if (value.toInt() < 0 || value.toInt() >= labels.length) {
                      return const SizedBox();
                    }
                    final etiqueta = labels[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: obtenerColorPorEtiqueta(
                            etiqueta,
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          obtenerIconoPorEtiqueta(etiqueta),
                          color: obtenerColorPorEtiqueta(etiqueta),
                          size: isTablet ? 20 : 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            barGroups: List.generate(labels.length, (i) {
              final key = labels[i];
              final percent = data[key] ?? 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: percent,
                    color: obtenerColorPorEtiqueta(key),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isTablet ? 8 : 6),
                    ),
                    width: barWidth,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: Colors.grey[100]!,
                    ),
                  ),
                ],
              );
            }),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            minY: 0,
            maxY: 100,
          ),
          swapAnimationDuration: const Duration(milliseconds: 600),
          swapAnimationCurve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  Widget _buildMovementTile(Movimiento mov, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.label_important_rounded, color: color, size: 20),
        ),
        title: Text(
          mov.concepto,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatoFechaHora(mov.fecha),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildPaymentMethodChip(mov),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Q${mov.monto.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              mov.tipo == 'ingreso' ? 'Ingreso' : 'Gasto',
              style: TextStyle(
                color:
                    mov.tipo == 'ingreso'
                        ? const Color(0xFF18BC9C)
                        : const Color(0xFFE74C3C),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(Movimiento mov) {
    if (mov.metodoPago == null || mov.metodoPago == 'Efectivo') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF16A085).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.money, color: Color(0xFF16A085), size: 14),
            SizedBox(width: 4),
            Text(
              "Efectivo",
              style: TextStyle(fontSize: 12, color: Color(0xFF16A085)),
            ),
          ],
        ),
      );
    }
    if (mov.metodoPago == 'Tarjeta Débito') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00BFAE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.credit_card, color: Color(0xFF00BFAE), size: 14),
            SizedBox(width: 4),
            Text(
              "Débito",
              style: TextStyle(fontSize: 12, color: Color(0xFF00BFAE)),
            ),
          ],
        ),
      );
    }
    if (mov.metodoPago == 'Tarjeta Crédito') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.credit_card, color: Color(0xFF1976D2), size: 14),
            SizedBox(width: 4),
            Text(
              "Crédito",
              style: TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF2C3E50),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            mov.metodoPago!,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
          ),
        ],
      ),
    );
  }

  String _formatoFechaHora(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');
    return '$day/$month/${fecha.year}  $hour:$minute';
  }
}
