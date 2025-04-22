//Pantalla creada por José Morales

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
      navIndex: 1, // Ajusta según tu menú lateral
      mostrarBotonHome: true, // Para volver al resumen
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

  // 🔑 Claves separadas para cada formulario
  final _formKeyIngreso = GlobalKey<FormState>();
  final _formKeyEgreso = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  double _monto = 0;
  String _concepto = '';
  String _etiqueta = '';
  String _metodoPago = 'Efectivo';

  final List<String> _etiquetasIngresos = [
    'Salario', 'Freelance', 'Inversiones', 'Regalo', 'Otros'
  ];

  final List<String> _etiquetasEgresos = [
    'Comida', 'Transporte', 'Entretenimiento', 'Servicios', 'Renta', 'Otros'
  ];

  final List<String> _metodosPago = [
    'Efectivo', 'Tarjeta Débito', 'Tarjeta Crédito'
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
        // --- TabBar para seleccionar tipo ---
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

        // --- Vistas de los formularios ---
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

            // Monto
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
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

            // Concepto
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

            // Etiqueta
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

            // Botón Guardar
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

            // Monto
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
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

            // Concepto
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

            // Etiqueta
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

            // Método de pago
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
              value: _metodoPago,
              items: _metodosPago
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => _metodoPago = value!,
            ),
            const SizedBox(height: 30),

            // Botón Guardar
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

  void _submitForm() {
    final isIngreso = _tabController.index == 0;
    final formKey = isIngreso ? _formKeyIngreso : _formKeyEgreso;

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      final movimiento = {
        'tipo': isIngreso ? 'ingreso' : 'egreso',
        'fecha': _fecha,
        'monto': _monto,
        'concepto': _concepto,
        'etiqueta': _etiqueta,
        if (!isIngreso) 'metodoPago': _metodoPago,
      };

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
      });
    }
  }

  // Reutilizable: ícono tipo movimiento
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

  // Reutilizable: selector de fecha
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
