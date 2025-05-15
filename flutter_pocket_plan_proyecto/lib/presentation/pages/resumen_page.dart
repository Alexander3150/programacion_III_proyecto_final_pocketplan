// Pantalla creada por José Morales
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/widgets/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/registros_ie_page.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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

// -------------------- PARTE 1: StatefulWidget y Estado Principal --------------------
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  // -------------------- PARTE 2: Métodos de construcción principales --------------------
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
          const Text(
            'PRESUPUESTO ACTUAL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Q. 12,450.00',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _tabController.index == 0 ? _ingresosColor : _egresosColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tabController.index == 0
                ? 'Total de ingresos en el periodo'
                : 'Total de egresos en el periodo',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
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
                      setState(() => _selectedPeriod = value!);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroMovimientoScreen(),
                ),
              );
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

  // -------------------- PARTE 3: Métodos para construir los tabs --------------------
  Widget _buildIngresosTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ResumenList(
              items: [
                _ResumenItem(
                  icon: Icons.monetization_on,
                  label: 'Salario',
                  value: '45%',
                  amount: '5,000.00',
                  color: Color(0xFF18BC9C),
                ),
                _ResumenItem(
                  icon: Icons.work_outline,
                  label: 'Freelance',
                  value: '30%',
                  amount: '3,300.00',
                  color: Color(0xFF2ECC71),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEgresosTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ResumenList(
              items: [
                _ResumenItem(
                  icon: Icons.shopping_cart,
                  label: 'Compras',
                  value: '35%',
                  amount: '1,500.00',
                  color: Color(0xFFE74C3C),
                ),
                _ResumenItem(
                  icon: Icons.home_work_outlined,
                  label: 'Renta',
                  value: '25%',
                  amount: '1,100.00',
                  color: Color(0xFFF39C12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildIngresosChartSections() {
    return [
      PieChartSectionData(
        value: 45,
        title: '45%',
        color: const Color(0xFF18BC9C),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 30,
        title: '30%',
        color: const Color(0xFF2ECC71),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  List<PieChartSectionData> _buildEgresosChartSections() {
    return [
      PieChartSectionData(
        value: 35,
        title: '35%',
        color: const Color(0xFFE74C3C),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 25,
        title: '25%',
        color: const Color(0xFFF39C12),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}

// -------------------- PARTE 4: Widgets auxiliares --------------------
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