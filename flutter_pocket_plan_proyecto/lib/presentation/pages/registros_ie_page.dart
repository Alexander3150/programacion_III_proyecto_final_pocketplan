import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/movimiento_model.dart';
import '../../data/models/repositories/movimiento_repository.dart';
import '../../data/models/repositories/tarjeta_credito_repository.dart';
import '../../data/models/repositories/tarjeta_debito_repository.dart';
import '../../data/models/credit_card_model.dart';
import '../../data/models/debit_card_model.dart';
import '../providers/user_provider.dart';
import '../widgets/global_components.dart';
import 'history_cards_screen.dart';

class RegistroMovimientoScreen extends StatelessWidget {
  final String tipoInicial;
  const RegistroMovimientoScreen({super.key, this.tipoInicial = 'ingreso'});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/resumen');
        return false;
      },
      child: GlobalLayout(
        titulo: 'Registrar Movimiento',
        body: _RegistroMovimientoTabs(tipoInicial: tipoInicial),
        mostrarDrawer: true,
        navIndex: 1,
        mostrarBotonHome: true,
      ),
    );
  }
}

class CampoConTooltip extends StatefulWidget {
  final Widget child;
  final String tooltip;
  final bool esIngreso;

  const CampoConTooltip({
    super.key,
    required this.child,
    required this.tooltip,
    required this.esIngreso,
  });

  @override
  State<CampoConTooltip> createState() => _CampoConTooltipState();
}

class _CampoConTooltipState extends State<CampoConTooltip> {
  bool _mostrarTooltip = false;

  void _mostrar() {
    setState(() => _mostrarTooltip = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mostrarTooltip = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: widget.child),
        const SizedBox(width: 6),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.help_outline,
                color:
                    widget.esIngreso
                        ? const Color(0xFF13BDBD)
                        : const Color(0xFFF44336),
              ),
              onPressed: _mostrar,
              splashRadius: 18,
              tooltip: "Ayuda",
            ),
            if (_mostrarTooltip)
              Positioned(
                right: 30,
                top: -20,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 180),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder:
                      (_, value, child) =>
                          Opacity(opacity: value, child: child),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            widget.esIngreso
                                ? [Color(0xFF13BDBD), Color(0xFF60B6F7)]
                                : [Color(0xFFFFB07C), Color(0xFFF44336)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.esIngreso
                                  ? Color(0xFF13BDBD)
                                  : Color(0xFFF44336))
                              .withOpacity(0.14),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.tooltip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final List<List<String>> _tooltipTexts = [
  [
    'Puede seleccionar la fecha en la que recibió su ingreso. Puede ser anterior o igual a hoy.',
    'Ingrese el monto de su ingreso recibido.',
    'Se recomienda iniciar con un título para mayor claridad, después puede adjuntar el motivo de su ingreso. Ejemplo: "Pago de nómina".',
    'Seleccione la etiqueta con la que desea guardar su ingreso. Si no aparece, elija "Otros" y detalle en concepto.',
  ],
  [
    'Seleccione la fecha en la que realizó el egreso. Debe ser una fecha pasada o la actual.',
    'Ingrese el monto exacto de su egreso.',
    'Inicie con un título y detalle el gasto realizado. Ejemplo: "Pago de luz".',
    'Seleccione la etiqueta que más se ajuste a su gasto. Si no aparece, seleccione "Otros" y detalle en concepto.',
    'Seleccione el método de pago: efectivo, tarjeta débito o tarjeta crédito. Si es tarjeta, elija tipo y la tarjeta usada.',
  ],
];

class _RegistroMovimientoTabs extends StatefulWidget {
  final String tipoInicial;
  const _RegistroMovimientoTabs({this.tipoInicial = 'ingreso'});

  @override
  State<_RegistroMovimientoTabs> createState() =>
      _RegistroMovimientoTabsState();
}

class _RegistroMovimientoTabsState extends State<_RegistroMovimientoTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKeyIngreso = GlobalKey<FormState>();
  final _formKeyGasto = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  double _monto = 0;
  String _concepto = '';
  String _etiquetaIngreso = '';
  String _etiquetaGasto = '';
  String _metodoPago = 'Efectivo';
  String? _selectedCardType;
  int? _selectedCard;
  String? _creditPaymentOption;
  int? _installments;

  List<CreditCard> _creditCards = [];
  List<DebitCard> _debitCards = [];
  int? _userId;

  final List<String> _etiquetasIngresos = [
    'Salario',
    'Freelance',
    'Inversiones',
    'Regalo',
    'Otros',
  ];

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
    int initialIndex =
        widget.tipoInicial == 'egreso' || widget.tipoInicial == 'gasto' ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _etiquetaIngreso = _etiquetasIngresos.first;
    _etiquetaGasto = _etiquetasGastos.first;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (!mounted) return;
        setState(() {
          if (_tabController.index == 0) {
            _etiquetaIngreso = _etiquetasIngresos.first;
          } else {
            _etiquetaGasto = _etiquetasGastos.first;
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _userId = userProvider.usuario?.id;
    _cargarTarjetas();
  }

  Future<void> _cargarTarjetas() async {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: limita el ancho en tablets/escritorio, pero permite todo el alto disponible
        final bool isWide = constraints.maxWidth > 650;
        final double maxWidth = isWide ? 480 : constraints.maxWidth;
        final EdgeInsets outerPadding =
            isWide
                ? const EdgeInsets.symmetric(horizontal: 70, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 10);

        // ========== Nuevo: usa SingleChildScrollView general y limita el ancho ==========
        return Center(
          child: SingleChildScrollView(
            child: Container(
              width: maxWidth,
              padding: outerPadding,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Icono GRANDE según el tipo actual
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child:
                        _tabController.index == 0
                            ? Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF13BDBD),
                                    Color(0xFF60B6F7),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 48,
                              ),
                            )
                            : Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFB07C),
                                    Color(0xFFF44336),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: const Icon(
                                Icons.trending_down,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color:
                            _tabController.index == 0
                                ? const Color(0xFF13BDBD)
                                : const Color(0xFFF44336),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      tabs: const [Tab(text: 'INGRESO'), Tab(text: 'GASTO')],
                      onTap: (index) => setState(() {}),
                    ),
                  ),
                  // ========== NUEVO: limita el alto máximo y permite scroll interno en formularios ==========
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.78,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFormularioIngreso(context, maxWidth),
                        _buildFormularioGasto(context, maxWidth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormularioIngreso(BuildContext context, double maxWidth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Form(
          key: _formKeyIngreso,
          child: Column(
            children: [
              const SizedBox(height: 14),
              CampoConTooltip(
                esIngreso: true,
                tooltip: _tooltipTexts[0][0],
                child: _buildDatePicker(context),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: true,
                tooltip: _tooltipTexts[0][1],
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: 'Q ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingrese un monto';
                    final monto = double.tryParse(value);
                    if (monto == null) return 'Monto inválido';
                    if (monto < 0) return 'El monto no puede ser negativo';
                    if (monto > 999999.99) return 'El monto es demasiado alto';
                    return null;
                  },
                  onSaved: (value) => _monto = double.parse(value!),
                ),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: true,
                tooltip: _tooltipTexts[0][2],
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Por ejemplo: Pago de nómina',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingrese un concepto';
                    if (value.length > 50)
                      return 'El concepto no debe exceder 50 caracteres';
                    return null;
                  },
                  onSaved: (value) => _concepto = value!,
                ),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: true,
                tooltip: _tooltipTexts[0][3],
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    border: OutlineInputBorder(),
                  ),
                  value: _etiquetaIngreso,
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
                    if (value != null) {
                      setState(() => _etiquetaIngreso = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 42),
              ElevatedButton(
                onPressed: _submitFormIngreso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13BDBD),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'REGISTRAR INGRESO',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioGasto(BuildContext context, double maxWidth) {
    final isCredit = _metodoPago == 'Tarjeta Crédito';
    final selectedCreditCard =
        isCredit && _selectedCard != null
            ? _creditCards.firstWhere(
              (card) => card.id == _selectedCard,
              orElse: () => null as CreditCard,
            )
            : null;

    double saldoDisponible = 0;
    if (selectedCreditCard != null) {
      saldoDisponible = selectedCreditCard.saldo;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Form(
          key: _formKeyGasto,
          child: Column(
            children: [
              const SizedBox(height: 14),
              CampoConTooltip(
                esIngreso: false,
                tooltip: _tooltipTexts[1][0],
                child: _buildDatePicker(context),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: false,
                tooltip: _tooltipTexts[1][1],
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: 'Q ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingrese un monto';
                    final monto = double.tryParse(value);
                    if (monto == null) return 'Monto inválido';
                    if (monto < 0) return 'El monto no puede ser negativo';
                    if (monto > 999999.99) return 'El monto es demasiado alto';
                    return null;
                  },
                  onSaved: (value) => _monto = double.parse(value!),
                ),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: false,
                tooltip: _tooltipTexts[1][2],
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    hintText: 'Por ejemplo: Pago de luz',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingrese un concepto';
                    if (value.length > 50)
                      return 'El concepto no debe exceder 50 caracteres';
                    return null;
                  },
                  onSaved: (value) => _concepto = value!,
                ),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: false,
                tooltip: _tooltipTexts[1][3],
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    border: OutlineInputBorder(),
                  ),
                  value: _etiquetaGasto,
                  items:
                      _etiquetasGastos
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
                    if (value != null) {
                      setState(() => _etiquetaGasto = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 18),
              CampoConTooltip(
                esIngreso: false,
                tooltip: _tooltipTexts[1][4],
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(),
                  ),
                  value: _metodoPago,
                  items:
                      _metodosPago
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
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
              ),
              if (_metodoPago == 'Tarjeta Débito' ||
                  _metodoPago == 'Tarjeta Crédito')
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Tarjeta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Tarjeta',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryCardsScreen(),
                            ),
                          ).then((_) => _cargarTarjetas());
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 14),
                          child: Text(
                            '¿No ves tu tarjeta? Agrega una nueva en la sección Tarjetas',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedCardType == 'Crédito' &&
                          _selectedCard != null &&
                          selectedCreditCard != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Saldo disponible: Q${saldoDisponible.toStringAsFixed(2)} / Límite: Q${selectedCreditCard.limite.toStringAsFixed(2)}',
                            style: TextStyle(
                              color:
                                  saldoDisponible > 0
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_selectedCardType == 'Crédito' &&
                          _selectedCard != null)
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
                                    maxLength: 2,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
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
                  ),
                ),
              const SizedBox(height: 42),
              ElevatedButton(
                onPressed: _submitFormGasto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'REGISTRAR GASTO',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _fecha,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          if (!mounted) return;
          setState(() => _fecha = picked);
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
    );
  }

  void _submitFormIngreso() async {
    final formKey = _formKeyIngreso;
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (_userId == null) return;

      final movimiento = Movimiento(
        userId: _userId!,
        tipo: 'ingreso',
        fecha: _fecha,
        monto: _monto,
        concepto: _concepto,
        etiqueta: _etiquetaIngreso,
        createdAt: DateTime.now(),
      );

      await MovimientoRepository().insertMovimiento(movimiento);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingreso registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(movimiento);

      if (!mounted) return;
      formKey.currentState!.reset();
      setState(() => _resetForm());
    }
  }

  void _submitFormGasto() async {
    final formKey = _formKeyGasto;
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (_userId == null) return;

      int? tarjetaId;
      if (_metodoPago != 'Efectivo' && _selectedCard != null) {
        tarjetaId = _selectedCard;
      }

      final movimiento = Movimiento(
        userId: _userId!,
        tipo: 'egreso',
        fecha: _fecha,
        monto: _monto,
        concepto: _concepto,
        etiqueta: _etiquetaGasto,
        metodoPago: _metodoPago,
        tarjetaId: tarjetaId,
        tipoTarjeta: _selectedCardType,
        opcionPago: _creditPaymentOption,
        cuotas: _installments,
        createdAt: DateTime.now(),
      );

      if (_metodoPago == 'Tarjeta Crédito' &&
          _selectedCardType == 'Crédito' &&
          tarjetaId != null) {
        final creditoRepo = TarjetaCreditoRepository();
        final creditCard = _creditCards.firstWhere(
          (card) => card.id == tarjetaId,
        );
        if (_monto > creditCard.saldo) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saldo insuficiente. Saldo disponible en la tarjeta: Q${creditCard.saldo.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await creditoRepo.actualizarSaldoTarjeta(
          creditCard.id!,
          creditCard.saldo - _monto,
          _userId!,
        );
        await _cargarTarjetas();
      }

      await MovimientoRepository().insertMovimiento(movimiento);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(movimiento);

      if (!mounted) return;
      formKey.currentState!.reset();
      setState(() => _resetForm());
    }
  }

  void _resetForm() {
    _fecha = DateTime.now();
    _monto = 0;
    _concepto = '';
    _metodoPago = 'Efectivo';
    _selectedCard = null;
    _selectedCardType = null;
    _creditPaymentOption = null;
    _installments = null;
  }
}
