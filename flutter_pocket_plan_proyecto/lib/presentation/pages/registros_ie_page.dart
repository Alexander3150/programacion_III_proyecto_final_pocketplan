import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/widgets/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/presentation/pages/resumen_page.dart';
//import 'package:flutter_pocket_plan_proyecto/pages/tarjetas_page.dart';

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
  String _etiqueta = '';
  String _metodoPago = 'Efectivo';

  // Nuevas variables para el sistema de tarjetas
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

  // Listas de tarjetas de ejemplo
  final List<String> _debitCards = ['Visa ****1234', 'Mastercard ****5678'];
  final List<String> _creditCards = ['Visa ****4321', 'Mastercard ****8765'];
  final List<String> _creditOptions = ['Al contado', 'A cuotas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _etiqueta = _etiquetasIngresos.first;
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
              color:
                  _tabController.index == 0
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
              items:
                  _etiquetasIngresos
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Seleccione una etiqueta';
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() => _etiqueta = value);
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
              items:
                  _etiquetasEgresos
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Seleccione una etiqueta';
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() => _etiqueta = value);
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

            // Sección de tarjetas (solo para pagos con tarjeta)
            if (_metodoPago == 'Tarjeta Débito' ||
                _metodoPago == 'Tarjeta Crédito')
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

                    // Fila para tipo de tarjeta y selección (ahora en misma fila)
                    Row(
                      children: [
                        // Tipo de tarjeta (ocupará 1/3 del espacio)
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
                                  child: Text(
                                    'Débito',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (_metodoPago == 'Tarjeta Crédito')
                                const DropdownMenuItem(
                                  value: 'Crédito',
                                  child: Text(
                                    'Crédito',
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

                        // Selección de tarjeta (ocupará 2/3 del espacio)
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
                            items:
                                (_selectedCardType == 'Débito'
                                        ? _debitCards
                                        : _creditCards)
                                    .map(
                                      (card) => DropdownMenuItem(
                                        value: card,
                                        child: Text(
                                          card,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
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

                    // Opciones para tarjeta de crédito (debajo, en columna normal)
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
                                if (value != 'A cuotas') {
                                  _installments = null;
                                }
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

                    // Enlace para agregar tarjetas
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResumenScreen(),
                          ),
                        ).then((_) {
                          setState(() {});
                        });
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

  void _submitForm() {
    final isIngreso = _tabController.index == 0;
    final formKey = isIngreso ? _formKeyIngreso : _formKeyEgreso;

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      // Validación adicional para pagos con tarjeta
      if (!isIngreso &&
          (_metodoPago == 'Tarjeta Débito' ||
              _metodoPago == 'Tarjeta Crédito') &&
          (_selectedCard == null || _selectedCardType == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor complete los detalles de la tarjeta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final movimiento = {
        'tipo': isIngreso ? 'ingreso' : 'egreso',
        'fecha': _fecha,
        'monto': _monto,
        'concepto': _concepto,
        'etiqueta': _etiqueta,
        if (!isIngreso) 'metodoPago': _metodoPago,
        if (!isIngreso && _selectedCard != null) 'tarjeta': _selectedCard,
        if (!isIngreso && _selectedCardType != null)
          'tipoTarjeta': _selectedCardType,
        if (!isIngreso && _creditPaymentOption != null)
          'opcionPago': _creditPaymentOption,
        if (!isIngreso && _installments != null) 'cuotas': _installments,
      };

      print('Movimiento registrado: $movimiento');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIngreso
                ? 'Ingreso registrado correctamente'
                : 'Egreso registrado correctamente',
          ),
          backgroundColor:
              isIngreso ? const Color(0xFF18BC9C) : const Color(0xFFE74C3C),
        ),
      );

      formKey.currentState!.reset();
      setState(() {
        _fecha = DateTime.now();
        _metodoPago = 'Efectivo';
        _selectedCard = null;
        _selectedCardType = null;
        _creditPaymentOption = null;
        _installments = null;
      });
    }
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
