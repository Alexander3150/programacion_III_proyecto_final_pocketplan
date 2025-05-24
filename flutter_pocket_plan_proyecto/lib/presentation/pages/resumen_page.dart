import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../data/models/repositories/movimiento_repository.dart';
import '../../data/models/repositories/tarjeta_credito_repository.dart';
import '../../data/models/repositories/tarjeta_debito_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/models/credit_card_model.dart';
import '../../data/models/debit_card_model.dart';
import '../widgets/global_components.dart';
import '../providers/user_provider.dart';
import '../widgets/resumen_grafico.dart';
import 'registros_ie_page.dart';

class ResumenScreen extends StatelessWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Resumen Financiero',
      body: const _ResumenTabs(),
      mostrarDrawer: true,
      navIndex: 0,
      mostrarBotonInforme: true,
      tipoInforme: 'financiero',
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
  UserModel? _usuario;
  double? _presupuestoInicial;
  int _mesGuardado = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarioYMovimientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: true);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final isTall = constraints.maxHeight > 800;

          // ========== RESPONSIVE: define máximos ==========
          final double maxWidth = isWide ? 700 : constraints.maxWidth;
          final EdgeInsetsGeometry mainPadding =
              isWide
                  ? EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.13,
                  )
                  : EdgeInsets.symmetric(horizontal: 10);

          double availableHeight = constraints.maxHeight;
          // Reserva espacio para topBar, gráfica, botones
          double listMaxHeight = availableHeight - 380;
          if (listMaxHeight < 120) listMaxHeight = 120;

          // Contenido principal de la columna
          Widget contenido = Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: maxWidth,
              padding: mainPadding,
              child: Column(
                children: [
                  _buildBudgetDisplay(context, userProvider),
                  _buildPeriodSelector(context),
                  _buildTabBar(),
                  // ========== Aquí aseguramos que la vista de Tab nunca desborde ==========
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 120,
                      maxHeight: listMaxHeight,
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTab(context, 'ingreso'),
                        _buildTab(context, 'egreso'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          // En tablets, centra el contenido y permite scroll general si falta espacio vertical
          if (isWide) {
            return Center(
              child: SingleChildScrollView(
                child: Container(width: 700, child: contenido),
              ),
            );
          }
          // En móvil: permite scroll solo si es necesario (pantalla pequeña)
          return SingleChildScrollView(
            child: Container(width: maxWidth, child: contenido),
          );
        },
      ),
    );
  }

  Future<void> _cargarUsuarioYMovimientos() async {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final user = userProvider.usuario;
    if (user != null) {
      _usuario = user;

      if (_presupuestoInicial == null && user.presupuesto != null) {
        _presupuestoInicial = user.presupuesto!;
        _mesGuardado = DateTime.now().month;
      }

      final mesActual = DateTime.now().month;
      if (mesActual != _mesGuardado) {
        final double presupuestoActualTemp = presupuestoActual;
        _presupuestoInicial = presupuestoActualTemp;
        _mesGuardado = mesActual;
        if (_usuario != null) {
          await userProvider.actualizarPresupuestoUsuario(
            _usuario!.id!,
            _presupuestoInicial!,
          );
        }
      }

      final movimientos = await MovimientoRepository().getMovimientosByUser(
        user.id!,
      );
      if (mounted) {
        setState(() {
          _movimientos = movimientos;
        });
      }
    }
  }

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

  double get presupuestoActual {
    if (_presupuestoInicial == null) return 0;
    final totalIngresos = _movimientos
        .where((m) => m.tipo == 'ingreso')
        .fold(0.0, (sum, m) => sum + m.monto);
    final totalEgresos = _movimientos
        .where((m) => m.tipo == 'egreso')
        .fold(0.0, (sum, m) => sum + m.monto);
    return _presupuestoInicial! + totalIngresos - totalEgresos;
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
          title: const Text('Editar presupuesto mensual inicial'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: TextField(
              controller: controlador,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Presupuesto mensual inicial',
              ),
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

  Widget _buildBudgetDisplay(
    BuildContext context,
    UsuarioProvider userProvider,
  ) {
    final presupuesto = presupuestoActual;
    final nombreUsuario = userProvider.usuario?.username ?? 'usuario';

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 700),
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
                  Flexible(
                    child: Text(
                      "PRESUPUESTO ACTUAL",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () async {
                      double? nuevoPresupuesto =
                          await _mostrarDialogoPresupuesto(
                            context,
                            _presupuestoInicial ?? 0,
                          );
                      if (nuevoPresupuesto != null && _usuario != null) {
                        await userProvider.actualizarPresupuestoUsuario(
                          _usuario!.id!,
                          nuevoPresupuesto,
                        );
                        setState(() {
                          _presupuestoInicial = nuevoPresupuesto;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "Q. ${presupuesto.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                ),
              ),
              if (_presupuestoInicial != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Presupuesto mensual inicial: Q. ${_presupuestoInicial!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.date_range, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Periodo: ${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 10,
          right: 28,
          child: Tooltip(
            showDuration: const Duration(seconds: 7),
            message:
                "¡Hola $nombreUsuario! 👋\n\nTu presupuesto mensual inicial se actualizará automáticamente el primer día de cada mes con el saldo que tengas en ese momento.\n\nSi lo prefieres, también puedes modificarlo manualmente tocando el lápiz en la parte superior derecha.",
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2075A7),
              borderRadius: BorderRadius.circular(10),
            ),
            verticalOffset: 30,
            preferBelow: false,
            triggerMode: TooltipTriggerMode.tap,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
              Widget screen;
              if (_tabController.index == 0) {
                screen = const RegistroMovimientoScreen(tipoInicial: 'ingreso');
              } else {
                screen = const RegistroMovimientoScreen(tipoInicial: 'egreso');
              }
              final nuevoMovimiento = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
              if (nuevoMovimiento != null && nuevoMovimiento is Movimiento) {
                await _cargarUsuarioYMovimientos();
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
    final ancho = MediaQuery.of(context).size.width;
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
          insets: EdgeInsets.symmetric(horizontal: ancho * 0.1),
        ),
        labelColor: _tabController.index == 0 ? _ingresosColor : _egresosColor,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [Tab(text: 'INGRESOS'), Tab(text: 'GASTOS')],
        onTap: (index) => setState(() {}),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String tipo) {
    final movimientos =
        _filtrarMovimientosConIndice(
          tipo,
          _dateRange,
        ).map((e) => e['movimiento'] as Movimiento).toList();
    final totalTipo = _calcularTotal(tipo, _dateRange);
    final distribucion = _obtenerDistribucion(tipo, _dateRange);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding:
              constraints.maxWidth > 700
                  ? EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.12,
                  )
                  : EdgeInsets.zero,
          child: Column(
            children: [
              if (distribucion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height:
                        constraints.maxWidth < 480
                            ? 230
                            : (constraints.maxWidth > 900 ? 330 : 280),
                    child: ResumenGrafico(
                      distribucion: distribucion,
                      obtenerColorPorEtiqueta: _obtenerColorPorEtiqueta,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    tipo == 'ingreso'
                        ? 'No hay ingresos registrados en este periodo'
                        : 'No hay gastos registrados en este periodo',
                  ),
                ),
              ..._buildGroupedList(context, tipo, movimientos, totalTipo),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    String tipo,
    List<Movimiento> movimientos,
    double totalTipo,
  ) {
    final agrupados = <String, List<Movimiento>>{};
    for (final mov in movimientos) {
      agrupados.putIfAbsent(mov.etiqueta, () => []).add(mov);
    }
    final widgets = <Widget>[];
    agrupados.forEach((etiqueta, listaMovs) {
      final icono = _obtenerIconoPorEtiqueta(etiqueta);
      final color = _obtenerColorPorEtiqueta(etiqueta);
      final montoTotal = listaMovs.fold<double>(0, (s, m) => s + m.monto);
      final porcentaje = totalTipo > 0 ? (montoTotal / totalTipo) * 100.0 : 0.0;
      widgets.add(
        _EtiquetaExpandableTile(
          icon: icono,
          color: color,
          etiqueta: etiqueta,
          porcentaje: porcentaje,
          montoTotal: montoTotal,
          movimientos: listaMovs,
          tipo: tipo,
          onUpdate: (_) async => await _cargarUsuarioYMovimientos(),
          buscarDatosTarjeta: _buscarDatosTarjeta,
          metodoPagoDetalle: _buildMetodoPagoDetalle,
        ),
      );
    });
    return widgets;
  }
}

Widget _buildMetodoPagoDetalle(BuildContext context, Movimiento mov) {
  if (mov.metodoPago == null) return const SizedBox.shrink();

  Widget iconoPago;
  Color colorFondo;
  if (mov.metodoPago == 'Tarjeta Crédito') {
    iconoPago = const Icon(
      Icons.credit_card,
      color: Color(0xFF2979FF),
      size: 20,
    );
    colorFondo = const Color(0xFFB6CCFF).withOpacity(0.14);
  } else if (mov.metodoPago == 'Tarjeta Débito') {
    iconoPago = const Icon(
      Icons.credit_card,
      color: Color(0xFF00BFAE),
      size: 20,
    );
    colorFondo = const Color(0xFF93F7D6).withOpacity(0.13);
  } else {
    iconoPago = const Icon(Icons.money, color: Colors.green, size: 18);
    colorFondo = Colors.green.withOpacity(0.08);
  }

  String tipo =
      mov.metodoPago == 'Tarjeta Crédito'
          ? 'Crédito'
          : mov.metodoPago == 'Tarjeta Débito'
          ? 'Débito'
          : mov.metodoPago!;

  if (mov.metodoPago == 'Tarjeta Débito' ||
      mov.metodoPago == 'Tarjeta Crédito') {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _buscarDatosTarjeta(context, mov),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.data == null) return const SizedBox();
        final tarjeta = snapshot.data!;
        final banco =
            (tarjeta['banco'] as String).length > 20
                ? (tarjeta['banco'] as String).substring(0, 20) + '…'
                : tarjeta['banco'] as String;
        final propietario =
            (tarjeta['propietario'] as String).length > 20
                ? (tarjeta['propietario'] as String).substring(0, 20) + '…'
                : tarjeta['propietario'] as String;
        final numero = tarjeta['numero'] ?? '';
        final ultimos4 =
            numero.length >= 4 ? numero.substring(numero.length - 4) : numero;

        return Container(
          margin: const EdgeInsets.only(top: 6, bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: colorFondo.withOpacity(0.35), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  iconoPago,
                  const SizedBox(height: 8),
                  Text(
                    tipo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banco,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Color(0xFF2C3E50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      propietario,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: Color(0xFF484848),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No. $ultimos4',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  } else {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconoPago,
        const SizedBox(width: 5),
        Text(
          tipo,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    );
  }
}

Future<Map<String, dynamic>?> _buscarDatosTarjeta(
  BuildContext context,
  Movimiento mov,
) async {
  if (mov.metodoPago == 'Tarjeta Crédito') {
    final repo = TarjetaCreditoRepository();
    final tarjeta = await repo.getTarjetaCreditoById(
      mov.tarjetaId!,
      mov.userId,
    );
    if (tarjeta == null) return null;
    return {
      'banco': tarjeta.banco,
      'propietario': tarjeta.alias,
      'numero': tarjeta.numero,
    };
  } else if (mov.metodoPago == 'Tarjeta Débito') {
    final repo = TarjetaDebitoRepository();
    final tarjeta = await repo.getTarjetaDebitoById(mov.tarjetaId!, mov.userId);
    if (tarjeta == null) return null;
    return {
      'banco': tarjeta.banco,
      'propietario': tarjeta.alias,
      'numero': tarjeta.numero,
    };
  }
  return null;
}

// ------- AQUÍ VA EL WIDGET DE TILE EXPANDIBLE ----------
// MODIFICA SÓLO ESTA PARTE PARA INCORPORAR LA LÓGICA AVANZADA QUE PEDISTE

class _EtiquetaExpandableTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String etiqueta;
  final double porcentaje;
  final double montoTotal;
  final List<Movimiento> movimientos;
  final String tipo;
  final void Function(Movimiento) onUpdate;
  final Future<Map<String, dynamic>?> Function(BuildContext, Movimiento)
  buscarDatosTarjeta;
  final Widget Function(BuildContext, Movimiento) metodoPagoDetalle;

  const _EtiquetaExpandableTile({
    required this.icon,
    required this.color,
    required this.etiqueta,
    required this.porcentaje,
    required this.montoTotal,
    required this.movimientos,
    required this.tipo,
    required this.onUpdate,
    required this.buscarDatosTarjeta,
    required this.metodoPagoDetalle,
    Key? key,
  }) : super(key: key);

  @override
  State<_EtiquetaExpandableTile> createState() =>
      _EtiquetaExpandableTileState();
}

class _EtiquetaExpandableTileState extends State<_EtiquetaExpandableTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            minVerticalPadding: 12,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 0,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.color),
            ),
            title: Text(
              widget.etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${widget.porcentaje.toStringAsFixed(1)}%'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Q${widget.montoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() => _expanded = !_expanded);
                  },
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Column(
              children:
                  widget.movimientos.map((mov) {
                    final porcentajeIndividual =
                        widget.montoTotal > 0
                            ? (mov.monto / widget.montoTotal) * 100
                            : 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 0,
                          ),
                          leading: Icon(widget.icon, color: widget.color),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  mov.concepto.length > 20
                                      ? mov.concepto.substring(0, 20) + '…'
                                      : mov.concepto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                'Q${mov.monto.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color:
                                      widget.tipo == 'ingreso'
                                          ? const Color(0xFF18BC9C)
                                          : const Color(0xFFE74C3C),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${porcentajeIndividual.toStringAsFixed(1)}%  | ${_formatoFechaHora(mov.fecha)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (widget.tipo == 'egreso')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: widget.metodoPagoDetalle(context, mov),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _mostrarEditarDialog(context, mov);
                              } else if (value == 'detalle') {
                                await _mostrarDetalleDialog(context, mov);
                              } else if (value == 'delete') {
                                await _eliminarMovimiento(context, mov);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                      title: Text('Modificar'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'detalle',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.visibility,
                                        color: Colors.blue,
                                      ),
                                      title: Text('Ver detalle'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: Text('Eliminar'),
                                    ),
                                  ),
                                ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatoFechaHora(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _mostrarEditarIngresoDialog(
    BuildContext context,
    Movimiento mov,
  ) async {
    final _formKey = GlobalKey<FormState>();
    DateTime _fecha = mov.fecha;
    double _monto = mov.monto;
    String _concepto = mov.concepto;
    String _etiqueta = mov.etiqueta;

    final List<String> _etiquetasIngresos = [
      'Salario',
      'Freelance',
      'Inversiones',
      'Regalo',
      'Otros',
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Ingreso'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // Selector de fecha
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: ctx,
                        initialDate: _fecha,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        _fecha = picked;
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Campo monto
                  TextFormField(
                    initialValue: _monto.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: 'Q ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 9, // 999999.99 máx (incluye el punto)
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Ingrese un monto';
                      final monto = double.tryParse(value);
                      if (monto == null) return 'Monto inválido';
                      if (monto < 0) return 'El monto no puede ser negativo';
                      if (monto > 999999.99)
                        return 'El monto es demasiado alto';
                      return null;
                    },
                    onSaved: (value) => _monto = double.parse(value!),
                  ),
                  const SizedBox(height: 8),
                  // Campo concepto
                  TextFormField(
                    initialValue: _concepto,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Ingrese un concepto';
                      if (value.length > 50) return 'Máximo 50 caracteres';
                      return null;
                    },
                    onSaved: (value) => _concepto = value!,
                  ),
                  const SizedBox(height: 12),
                  // Campo etiqueta
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta',
                      border: OutlineInputBorder(),
                    ),
                    value: _etiqueta,
                    items:
                        _etiquetasIngresos
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Seleccione una etiqueta';
                      return null;
                    },
                    onChanged: (value) {
                      if (value != null) _etiqueta = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18BC9C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Guardar'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                _formKey.currentState!.save();

                // Actualiza el movimiento
                final actualizado = Movimiento(
                  id: mov.id,
                  userId: mov.userId,
                  tipo: 'ingreso',
                  fecha: _fecha,
                  monto: _monto,
                  concepto: _concepto,
                  etiqueta: _etiqueta,
                  createdAt: mov.createdAt,
                );
                await MovimientoRepository().updateMovimiento(actualizado);
                widget.onUpdate(actualizado);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingreso actualizado correctamente'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- EDICIÓN y DETALLE AVANZADO para EGRESO ---
  Future<void> _mostrarEditarDialog(
    BuildContext context,
    Movimiento mov,
  ) async {
    if (mov.tipo == 'ingreso') {
      await _mostrarEditarIngresoDialog(context, mov);
      return;
    }
    // EDITAR EGRESO: formulario igual al de RegistroMovimientoScreen
    await showDialog(
      context: context,
      builder: (ctx) {
        // Copia aquí el formulario del gasto de RegistroMovimientoScreen adaptado.
        // Te recomiendo usar un StatefulBuilder para manejar el estado del formulario dentro del dialog.
        return _EditarGastoDialog(movimiento: mov, onUpdate: widget.onUpdate);
      },
    );
  }

  Future<void> _mostrarDetalleDialog(
    BuildContext context,
    Movimiento mov,
  ) async {
    CreditCard? tarjetaCredito;
    DebitCard? tarjetaDebito;

    if (mov.metodoPago == 'Tarjeta Crédito' &&
        mov.tarjetaId != null &&
        mov.userId != null) {
      tarjetaCredito = await TarjetaCreditoRepository().getTarjetaCreditoById(
        mov.tarjetaId!,
        mov.userId!,
      );
    } else if (mov.metodoPago == 'Tarjeta Débito' &&
        mov.tarjetaId != null &&
        mov.userId != null) {
      tarjetaDebito = await TarjetaDebitoRepository().getTarjetaDebitoById(
        mov.tarjetaId!,
        mov.userId!,
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Detalle de movimiento'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Concepto: ${mov.concepto}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text('Monto: Q${mov.monto.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Etiqueta: ${mov.etiqueta}'),
                const SizedBox(height: 8),
                Text('Fecha: ${_formatoFechaHora(mov.fecha)}'),
                const SizedBox(height: 8),
                if (mov.tipo == 'egreso' && mov.metodoPago != null)
                  Text('Método de pago: ${mov.metodoPago}'),
                if (tarjetaCredito != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  if (mov.tipoTarjeta != null)
                    Text('Tipo de tarjeta: ${mov.tipoTarjeta!}'),
                  const SizedBox(height: 6),
                  Text('Nombre del Banco: ${tarjetaCredito.banco}'),
                  const SizedBox(height: 6),
                  Text('Nombre del Propietario: ${tarjetaCredito.alias}'),
                  const SizedBox(height: 6),
                  Text(
                    'Número de tarjeta: ${tarjetaCredito.numero.length >= 4 ? tarjetaCredito.numero.substring(tarjetaCredito.numero.length - 4) : tarjetaCredito.numero}',
                  ),
                ],
                if (tarjetaDebito != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  if (mov.tipoTarjeta != null)
                    Text('Tipo de tarjeta: ${mov.tipoTarjeta!}'),
                  const SizedBox(height: 6),
                  Text('Nombre del Banco: ${tarjetaDebito.banco}'),
                  const SizedBox(height: 6),
                  Text('Nombre del Propietario: ${tarjetaDebito.alias}'),
                  const SizedBox(height: 6),
                  Text(
                    'Número de tarjeta: ${tarjetaDebito.numero.length >= 4 ? tarjetaDebito.numero.substring(tarjetaDebito.numero.length - 4) : tarjetaDebito.numero}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarMovimiento(BuildContext context, Movimiento mov) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Movimiento'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este movimiento?',
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
      // Si el gasto es con tarjeta de crédito, devuelve el saldo
      if (mov.tipo == 'egreso' &&
          mov.metodoPago == 'Tarjeta Crédito' &&
          mov.tarjetaId != null) {
        final creditoRepo = TarjetaCreditoRepository();
        final tarjeta = await creditoRepo.getTarjetaCreditoById(
          mov.tarjetaId!,
          mov.userId,
        );
        if (tarjeta != null) {
          final saldoActualizado = tarjeta.saldo + mov.monto;
          await creditoRepo.actualizarSaldoTarjeta(
            tarjeta.id!,
            saldoActualizado,
            tarjeta.userId!,
          );
        }
      }
      final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final userId = userProvider.usuario?.id;
      if (userId != null && mov.id != null) {
        await MovimientoRepository().deleteMovimiento(mov.id!, userId);
        widget.onUpdate(mov);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento eliminado'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ---------- DIÁLOGO DE EDICIÓN DE GASTO AVANZADO (igual que el registro de gasto) ----------

class _EditarGastoDialog extends StatefulWidget {
  final Movimiento movimiento;
  final void Function(Movimiento) onUpdate;

  const _EditarGastoDialog({required this.movimiento, required this.onUpdate});

  @override
  State<_EditarGastoDialog> createState() => _EditarGastoDialogState();
}

class _EditarGastoDialogState extends State<_EditarGastoDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  late double _monto;
  late String _concepto;
  late String _etiqueta;
  String _metodoPago = 'Efectivo';
  String? _selectedCardType;
  int? _selectedCard;
  String? _creditPaymentOption;
  int? _installments;
  int? _userId;

  List<CreditCard> _creditCards = [];
  List<DebitCard> _debitCards = [];

  final List<String> _etiquetasGastos = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Servicios',
    'Renta',
    'Otros',
  ];

  final List<String> _metodosPago = [
    'Efectivo',
    'Tarjeta Débito',
    'Tarjeta Crédito',
  ];

  final List<String> _creditOptions = ['Al contado', 'A cuotas'];

  @override
  void initState() {
    super.initState();
    _fecha = widget.movimiento.fecha;
    _monto = widget.movimiento.monto;
    _concepto = widget.movimiento.concepto;
    _etiqueta = widget.movimiento.etiqueta;
    _metodoPago = widget.movimiento.metodoPago ?? 'Efectivo';
    _selectedCardType = widget.movimiento.tipoTarjeta;
    _selectedCard = widget.movimiento.tarjetaId;
    _creditPaymentOption = widget.movimiento.opcionPago;
    _installments = widget.movimiento.cuotas;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarTarjetas());
  }

  Future<void> _cargarTarjetas() async {
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    if (_userId == null) return;
    final creditoRepo = TarjetaCreditoRepository();
    final debitoRepo = TarjetaDebitoRepository();
    final creditCards = await creditoRepo.getTarjetasCreditoByUser(_userId!);
    final debitCards = await debitoRepo.getTarjetasDebitoByUser(_userId!);
    if (!mounted) return;
    setState(() {
      _creditCards = creditCards;
      _debitCards = debitCards;
    });
  }

  List<DropdownMenuItem<int>> _buildDebitCardItems() {
    return _debitCards
        .map(
          (card) => DropdownMenuItem(
            value: card.id,
            child: Text(
              '${card.banco} - ${card.alias} - ${card.numero}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<int>> _buildCreditCardItems() {
    return _creditCards
        .map(
          (card) => DropdownMenuItem(
            value: card.id,
            child: Text(
              '${card.banco} - ${card.alias} - ${card.numero}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _metodoPago == 'Tarjeta Crédito';

    CreditCard? selectedCreditCard;
    if (isCredit && _selectedCard != null) {
      selectedCreditCard = _creditCards.firstWhereOrNull(
        (card) => card.id == _selectedCard,
      );
    } else {
      selectedCreditCard = null;
    }

    double saldoDisponible = 0;
    if (selectedCreditCard != null) {
      saldoDisponible = selectedCreditCard.saldo;
    }

    return AlertDialog(
      title: const Text('Editar Gasto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _fecha = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // CAMPO MONTO (máx. Q 999,999.99)
              TextFormField(
                initialValue: _monto.toString(),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: 'Q ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 9, // Para asegurar el límite de dígitos
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese un monto';
                  final monto = double.tryParse(value);
                  if (monto == null) return 'Monto inválido';
                  if (monto < 0) return 'El monto no puede ser negativo';
                  if (monto > 999999.99) return 'El monto es demasiado alto';
                  return null;
                },
                onSaved: (value) => _monto = double.parse(value!),
              ),
              const SizedBox(height: 12),

              // CAMPO CONCEPTO (máx. 40 caracteres)
              TextFormField(
                initialValue: _concepto,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Ingrese un concepto';
                  if (value.length > 50) return 'Máximo 50 caracteres';
                  return null;
                },
                onSaved: (value) => _concepto = value!,
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Etiqueta',
                  border: OutlineInputBorder(),
                ),
                value: _etiqueta,
                items:
                    _etiquetasGastos
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Seleccione una etiqueta';
                  return null;
                },
                onChanged: (value) {
                  if (value != null) setState(() => _etiqueta = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  border: OutlineInputBorder(),
                ),
                value: _metodoPago,
                items:
                    _metodosPago
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _metodoPago = value;
                      _selectedCard = null;
                      _selectedCardType = null;
                      _creditPaymentOption = null;
                      _installments = null;
                    });
                  }
                },
              ),
              if (_metodoPago == 'Tarjeta Débito' ||
                  _metodoPago == 'Tarjeta Crédito') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Tarjeta',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        value: _selectedCardType,
                        items: [
                          if (_metodoPago == 'Tarjeta Débito')
                            const DropdownMenuItem(
                              value: 'Débito',
                              child: Text('Débito'),
                            ),
                          if (_metodoPago == 'Tarjeta Crédito')
                            const DropdownMenuItem(
                              value: 'Crédito',
                              child: Text('Crédito'),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCardType = value;
                            _selectedCard = null;
                            _creditPaymentOption = null;
                            _installments = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Seleccione tarjeta',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        value: _selectedCard,
                        items:
                            _selectedCardType == 'Débito'
                                ? _buildDebitCardItems()
                                : _buildCreditCardItems(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCard = value;
                            if (_selectedCardType == 'Crédito') {
                              _creditPaymentOption = null;
                              _installments = null;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedCardType == 'Crédito' &&
                    _selectedCard != null &&
                    selectedCreditCard != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Saldo disponible: Q${saldoDisponible.toStringAsFixed(2)} / Límite: Q${selectedCreditCard.limite.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: saldoDisponible > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_selectedCardType == 'Crédito' && _selectedCard != null)
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Opción de pago',
                          border: OutlineInputBorder(),
                        ),
                        value: _creditPaymentOption,
                        items:
                            _creditOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _creditPaymentOption = value;
                            if (value != 'A cuotas') _installments = null;
                          });
                        },
                      ),
                      if (_creditPaymentOption == 'A cuotas')
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Número de cuotas',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 2, // <-- SOLO 2 dígitos
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // Solo números
                              ],
                              validator: (value) {
                                if (_creditPaymentOption == 'A cuotas') {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese número de cuotas';
                                  }
                                  final n = int.tryParse(value);
                                  if (n == null) return 'Número inválido';
                                  if (n < 1 || n > 48)
                                    return 'Debe ser entre 1 y 48 cuotas';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _installments = int.tryParse(value);
                                });
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Guardar'),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            _formKey.currentState!.save();
            // Actualiza saldo de tarjeta si corresponde (si cambia de tarjeta o monto)
            final userProvider = Provider.of<UsuarioProvider>(
              context,
              listen: false,
            );
            final userId = userProvider.usuario?.id;
            if (userId == null) return;

            // Si antes era con tarjeta de crédito, hay que sumar el monto antiguo al saldo de la tarjeta anterior
            if (widget.movimiento.metodoPago == 'Tarjeta Crédito' &&
                widget.movimiento.tarjetaId != null) {
              final creditoRepo = TarjetaCreditoRepository();
              final oldCard = await creditoRepo.getTarjetaCreditoById(
                widget.movimiento.tarjetaId!,
                userId,
              );
              if (oldCard != null) {
                await creditoRepo.actualizarSaldoTarjeta(
                  oldCard.id!,
                  oldCard.saldo + widget.movimiento.monto,
                  userId,
                );
              }
            }
            // Si el método nuevo es con tarjeta de crédito, resta el nuevo monto al saldo de la tarjeta
            if (_metodoPago == 'Tarjeta Crédito' && _selectedCard != null) {
              final creditoRepo = TarjetaCreditoRepository();
              final newCard = await creditoRepo.getTarjetaCreditoById(
                _selectedCard!,
                userId,
              );
              if (newCard != null && _monto <= newCard.saldo) {
                await creditoRepo.actualizarSaldoTarjeta(
                  newCard.id!,
                  newCard.saldo - _monto,
                  userId,
                );
              } else if (newCard != null && _monto > newCard.saldo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Saldo insuficiente en la tarjeta de crédito seleccionada.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }
            // Actualiza el movimiento
            final actualizado = Movimiento(
              id: widget.movimiento.id,
              userId: userId,
              tipo: 'egreso',
              fecha: _fecha,
              monto: _monto,
              concepto: _concepto,
              etiqueta: _etiqueta,
              metodoPago: _metodoPago,
              tarjetaId: _selectedCard,
              tipoTarjeta: _selectedCardType,
              opcionPago: _creditPaymentOption,
              cuotas: _installments,
              createdAt: widget.movimiento.createdAt,
            );
            await MovimientoRepository().updateMovimiento(actualizado);
            widget.onUpdate(actualizado);
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gasto actualizado correctamente'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
