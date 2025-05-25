import 'package:flutter/material.dart';

class DialogoFiltroInformeAhorros extends StatefulWidget {
  final String? estadoActual;
  final String? periodoActual;
  final DateTimeRange? rangoActual;

  const DialogoFiltroInformeAhorros({
    Key? key,
    this.estadoActual,
    this.periodoActual,
    this.rangoActual,
  }) : super(key: key);

  @override
  State<DialogoFiltroInformeAhorros> createState() =>
      _DialogoFiltroInformeAhorrosState();
}

class _DialogoFiltroInformeAhorrosState
    extends State<DialogoFiltroInformeAhorros> {
  late String _estado;
  late String _periodo;
  DateTimeRange? _dateRange;

  final List<String> estados = ['Todos', 'Completados', 'Pendientes'];
  final List<String> periodos = [
    'Ahorros Mensuales',
    'Ahorros Quincenales',
    'Ambos periodos', // <---- NUEVO
    'Personalizado',
  ];

  @override
  void initState() {
    super.initState();
    _estado = widget.estadoActual ?? 'Todos';
    _periodo = widget.periodoActual ?? 'Ahorros Mensuales';
    _dateRange = widget.rangoActual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          const Icon(Icons.savings, color: Color(0xFF18BC9C)),
          const SizedBox(width: 10),
          const Text('Filtrar Informe de Ahorros'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado del ahorro',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...estados.map(
              (estado) => RadioListTile<String>(
                title: Text(estado),
                value: estado,
                groupValue: _estado,
                activeColor: const Color(0xFF18BC9C),
                onChanged: (value) => setState(() => _estado = value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 10),
              child: Text(
                '¿Mostrar todos, solo los completados o los pendientes?',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              'Periodo del ahorro',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: _periodo,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items:
                  periodos
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) async {
                setState(() => _periodo = v!);
                if (v == 'Personalizado') {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dateRange = picked);
                } else {
                  _dateRange = null;
                }
              },
            ),
            if (_periodo == 'Personalizado' && _dateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Del ${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} '
                  'al ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            if (_periodo == 'Personalizado')
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'Selecciona el rango de fechas para mostrar ahorros creados en ese periodo.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics, size: 20),
          label: const Text('Ver informe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18BC9C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed:
              _periodo == 'Personalizado' && _dateRange == null
                  ? null // Deshabilita si falta rango
                  : () {
                    Navigator.pop(context, {
                      'estado': _estado,
                      'periodo': _periodo,
                      'dateRange': _dateRange,
                    });
                  },
        ),
      ],
    );
  }
}
