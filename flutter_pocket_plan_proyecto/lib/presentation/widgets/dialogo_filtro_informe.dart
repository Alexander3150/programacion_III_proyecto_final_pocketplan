import 'package:flutter/material.dart';

class DialogoFiltroInforme extends StatefulWidget {
  final String? tipoActual;
  final String? periodoActual;
  final DateTimeRange? rangoActual;

  const DialogoFiltroInforme({
    Key? key,
    this.tipoActual,
    this.periodoActual,
    this.rangoActual,
  }) : super(key: key);

  @override
  State<DialogoFiltroInforme> createState() => _DialogoFiltroInformeState();
}

class _DialogoFiltroInformeState extends State<DialogoFiltroInforme> {
  late String _tipo;
  late String _periodo;
  DateTimeRange? _dateRange;

  final List<String> tipos = ['Todo', 'Ingresos', 'Egresos'];
  final List<String> periodos = [
    'Día',
    'Semana',
    'Mes',
    'Año',
    'Personalizado',
  ];

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoActual ?? 'Todo';
    _periodo = widget.periodoActual ?? 'Mes';
    _dateRange = widget.rangoActual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPrimario = const Color(0xFF18BC9C);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 18, 8),
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorPrimario.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: const Icon(
              Icons.analytics,
              color: Color(0xFF18BC9C),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Filtrar Informe',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2C3E50),
              letterSpacing: .2,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro tipo de movimiento
            const SizedBox(height: 6),
            Text(
              '¿Qué movimientos mostrar?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...tipos.map(
              (tipo) => RadioListTile<String>(
                title: Text(tipo),
                value: tipo,
                groupValue: _tipo,
                activeColor: colorPrimario,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _tipo = value!),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 10),
              child: Text(
                'Filtra entre todos los movimientos, solo los ingresos o solo los egresos.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Divider(height: 24, thickness: 1, color: Colors.grey[200]),
            // Filtro periodo
            Text(
              'Periodo del informe',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButtonFormField<String>(
              value: _periodo,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF18BC9C)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF7FAF9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
              ),
              style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
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
                    builder:
                        (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: colorPrimario,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Color(0xFF2C3E50),
                            ),
                          ),
                          child: child!,
                        ),
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
                  'Selecciona un rango de fechas personalizado.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.insert_chart, size: 20),
          label: const Text('Ver informe', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimario,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () {
            Navigator.pop(context, {
              'tipo': _tipo,
              'periodo': _periodo,
              'dateRange': _dateRange,
            });
          },
        ),
      ],
    );
  }
}
