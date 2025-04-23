// Pantalla creada por José Morales
import 'package:flutter/material.dart';
import 'package:flutter_pocket_plan_proyecto/layout/global_components.dart';
import 'package:flutter_pocket_plan_proyecto/pages/resumen_page.dart';

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
  State<_RegistroMovimientoTabs> createState() => _RegistroMovimientoTabsState();
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
  String? _tarjetaSeleccionada;

  final List<String> _etiquetasIngresos = [
    'Salario', 'Freelance', 'Inversiones', 'Regalo', 'Otros'
  ];

  final List<String> _etiquetasEgresos = [
    'Comida', 'Transporte', 'Entretenimiento', 'Servicios', 'Renta', 'Otros'
  ];

  final List<String> _metodosPago = [
    'Efectivo', 'Tarjeta Débito', 'Tarjeta Crédito'
  ];

  // Lista simulada de tarjetas registradas
  final List<Map<String, dynamic>> _tarjetasRegistradas = [
    {
      'tipo': 'Tarjeta Crédito',
      'nombre': 'Visa Platinum',
      'ultimosDigitos': '•••• 4567',
      'icono': Icons.credit_card,
      'color': Colors.blue
    },
    {
      'tipo': 'Tarjeta Débito',
      'nombre': 'Cuenta Principal',
      'ultimosDigitos': '•••• 8910',
      'icono': Icons.account_balance,
      'color': Colors.green
    },
    {
      'tipo': 'Tarjeta Crédito',
      'nombre': 'Mastercard Gold',
      'ultimosDigitos': '•••• 1234',
      'icono': Icons.credit_card,
      'color': Colors.orange
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            tabs: const [
              Tab(text: 'INGRESO'),
              Tab(text: 'EGRESO'),
            ],
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
                if (value == null || value.isEmpty) return 'Ingrese un concepto';
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
              items: _etiquetasIngresos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Seleccione una etiqueta';
                return null;
              },
              onChanged: (value) => _etiqueta = value!,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18BC9C),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('REGISTRAR INGRESO', style: TextStyle(color: Colors.white)),
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
                if (value == null || value.isEmpty) return 'Ingrese un concepto';
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
              items: _etiquetasEgresos
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Seleccione una etiqueta';
                return null;
              },
              onChanged: (value) => _etiqueta = value!,
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
                setState(() {
                  _metodoPago = value!;
                  _tarjetaSeleccionada = null;
                });
              },
            ),
            
            // Mostrar selector de tarjetas solo si se seleccionó tarjeta
            if (_metodoPago == 'Tarjeta Débito' || _metodoPago == 'Tarjeta Crédito')
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar Tarjeta',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._buildListaTarjetas(),
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
              child: const Text('REGISTRAR EGRESO', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListaTarjetas() {
    // Filtrar tarjetas según el tipo seleccionado
    final tarjetasFiltradas = _tarjetasRegistradas.where((tarjeta) {
      return tarjeta['tipo'] == _metodoPago;
    }).toList();

    return tarjetasFiltradas.map((tarjeta) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tarjeta['color'].withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tarjeta['icono'], color: tarjeta['color']),
          ),
          title: Text(tarjeta['nombre']),
          subtitle: Text(tarjeta['ultimosDigitos']),
          trailing: _tarjetaSeleccionada == tarjeta['nombre']
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: () {
            setState(() {
              _tarjetaSeleccionada = tarjeta['nombre'];
            });
          },
        ),
      );
    }).toList();
  }

  void _submitForm() {
    final isIngreso = _tabController.index == 0;
    final formKey = isIngreso ? _formKeyIngreso : _formKeyEgreso;

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      // Validar tarjeta seleccionada si es pago con tarjeta
      if (!isIngreso && 
          (_metodoPago == 'Tarjeta Débito' || _metodoPago == 'Tarjeta Crédito') &&
          _tarjetaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione una tarjeta'),
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
        if (!isIngreso && _tarjetaSeleccionada != null) 
          'tarjeta': _tarjetaSeleccionada,
      };

      // Aquí normalmente enviarías los datos a tu base de datos
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
        _tarjetaSeleccionada = null;
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