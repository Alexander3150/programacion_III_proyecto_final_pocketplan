import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/movimiento_model.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/history_cards_screen.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/widgets/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/card_manager.dart';
import 'package:flutter_pocket_plan_proyecto/data/models/movimiento_repository.dart';

class RegistroMovimientoScreen extends StatelessWidget {
  const RegistroMovimientoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      titulo: 'Registrar Movimiento',
      body: const _RegistroMovimientoTabs(),
      mostrarDrawer: true,
      navIndex: 1,
      mostrarBotonHome: true,
    );
  }
}

class _RegistroMovimientoTabs extends StatefulWidget {
  const _RegistroMovimientoTabs();

  @override
  State<_RegistroMovimientoTabs> createState() =>
      _RegistroMovimientoTabsState();
}

class _RegistroMovimientoTabsState extends State<_RegistroMovimientoTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKeyIngreso = GlobalKey<FormState>();
  final _formKeyEgreso = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  double _monto = 0;
  String _concepto = '';
  String _etiquetaIngreso = '';
  String _etiquetaEgreso = '';
  String _metodoPago = 'Efectivo';
  String? _selectedCardType;
  String? _selectedCard;
  String? _creditPaymentOption;
  int? _installments;

  final List<String> _etiquetasIngresos = [
    'Salario',
    'Freelance',
    'Inversiones',
    'Regalo',
    'Otros',
  ];

  final List<String> _etiquetasEgresos = [
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
    _tabController = TabController(length: 2, vsync: this);
    _etiquetaIngreso = _etiquetasIngresos.first;
    _etiquetaEgreso = _etiquetasEgresos.first;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _etiquetaIngreso = _etiquetasIngresos.first;
          } else {
            _etiquetaEgreso = _etiquetasEgresos.first;
          }
        });
      }
    });
  }

  List<DropdownMenuItem<String>> _buildDebitCardItems() {
    return CardManager().debitCards.map((card) {
      final label = '${card.banco} - ${card.alias}';
      return DropdownMenuItem(
        value: card.id,
        child: Text(label, overflow: TextOverflow.ellipsis),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildCreditCardItems() {
    return CardManager().creditCards.map((card) {
      final label = '${card.banco} - ${card.alias}';
      return DropdownMenuItem(
        value: card.id,
        child: Text(label, overflow: TextOverflow.ellipsis),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _tabController.index == 0
                  ? const Color(0xFF18BC9C)
                  : const Color(0xFFE74C3C),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [Tab(text: 'INGRESO'), Tab(text: 'EGRESO')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormularioIngreso(context),
              _buildFormularioEgreso(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioIngreso(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyIngreso,
        child: Column(
          children: [
            _buildIconoTipo(Icons.trending_up, const Color(0xFF18BC9C)),
            const SizedBox(height: 20),
            _buildDatePicker(context),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: 'Q ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingrese un monto';
                if (double.tryParse(value) == null) return 'Monto inválido';
                return null;
              },
              onSaved: (value) => _monto = double.parse(value!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Ingrese un concepto';
                return null;
              },
              onSaved: (value) => _concepto = value!,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                border: OutlineInputBorder(),
              ),
              value: _etiquetaIngreso,
              items: _etiquetasIngresos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18BC9C),
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
    );
  }

  Widget _buildFormularioEgreso(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyEgreso,
        child: Column(
          children: [
            _buildIconoTipo(Icons.trending_down, const Color(0xFFE74C3C)),
            const SizedBox(height: 20),
            _buildDatePicker(context),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: 'Q ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingrese un monto';
                if (double.tryParse(value) == null) return 'Monto inválido';
                return null;
              },
              onSaved: (value) => _monto = double.parse(value!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Ingrese un concepto';
                return null;
              },
              onSaved: (value) => _concepto = value!,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Etiqueta',
                border: OutlineInputBorder(),
              ),
              value: _etiquetaEgreso,
              items: _etiquetasEgresos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Seleccione una etiqueta';
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() => _etiquetaEgreso = value);
                }
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
              value: _metodoPago,
              items: _metodosPago
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
            if (_metodoPago == 'Tarjeta Débito' || _metodoPago == 'Tarjeta Crédito')
              Padding(
                padding: const EdgeInsets.only(top: 20),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
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
                          child: DropdownButtonFormField<String>(
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
                            items: _selectedCardType == 'Débito'
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
                            items: _creditOptions
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
                                  validator: (value) {
                                    if (_creditPaymentOption == 'A cuotas' &&
                                        (value == null || value.isEmpty)) {
                                      return 'Ingrese número de cuotas';
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
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryCardsScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: const Text(
                        '¿No ves tu tarjeta? Agrega una nueva en la sección Tarjetas',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'REGISTRAR EGRESO',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    final isIngreso = _tabController.index == 0;
    final formKey = isIngreso ? _formKeyIngreso : _formKeyEgreso;
    final etiqueta = isIngreso ? _etiquetaIngreso : _etiquetaEgreso;

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      // --- Validación SOLO para egresos con tarjeta de crédito ---
      if (!isIngreso && _metodoPago == 'Tarjeta Crédito' && _selectedCard != null) {
        final cardManager = CardManager();
        final creditCardList = cardManager.creditCards.where(
          (card) => card.id == _selectedCard,
        ).toList();

        if (creditCardList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarjeta de crédito no encontrada'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final creditCard = creditCardList.first;

        // Validación contra el límite (valor estático)
        if (_monto > creditCard.limite) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'El monto excede el límite de la tarjeta.\nLímite: Q${creditCard.limite.toStringAsFixed(2)}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // (Resto igual...)

      final movimiento = Movimiento(
        tipo: isIngreso ? 'ingreso' : 'egreso',
        fecha: _fecha,
        monto: _monto,
        concepto: _concepto,
        etiqueta: etiqueta,
        metodoPago: isIngreso ? null : _metodoPago,
        tarjetaId: isIngreso ? null : _selectedCard,
        tipoTarjeta: isIngreso ? null : _selectedCardType,
        opcionPago: isIngreso ? null : _creditPaymentOption,
        cuotas: isIngreso ? null : _installments,
      );

      MovimientoRepository().agregarMovimiento(movimiento);

      Navigator.of(context).pop(movimiento);

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

  Widget _buildIconoTipo(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: color),
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
}
