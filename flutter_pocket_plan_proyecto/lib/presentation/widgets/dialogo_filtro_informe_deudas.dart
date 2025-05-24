import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogoFiltroInformeDeudas extends StatefulWidget {
  final String? estadoActual;
  final String? periodoActual;
  final DateTimeRange? rangoActual;

  const DialogoFiltroInformeDeudas({
    Key? key,
    this.estadoActual,
    this.periodoActual,
    this.rangoActual,
  }) : super(key: key);

  @override
  State<DialogoFiltroInformeDeudas> createState() =>
      _DialogoFiltroInformeDeudasState();
}

class _DialogoFiltroInformeDeudasState
    extends State<DialogoFiltroInformeDeudas> {
  late String _estado;
  late String _periodo;
  DateTimeRange? _dateRange;

  final List<String> estados = ['Todas', 'Completados', 'Pendientes'];
  final List<String> periodos = [
    'Mensual',
    'Quincenal',
    'Todos los periodos',
    'Personalizado',
  ];

  @override
  void initState() {
    super.initState();
    _estado = widget.estadoActual ?? 'Todas';
    _periodo = widget.periodoActual ?? 'Todos los periodos';
    _dateRange = widget.rangoActual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.filter_alt_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 10),
          Text(
            'Filtrar Informe de Deudas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24, thickness: 1),
            const Text(
              'Estado de la deuda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            ...estados.map(
              (estado) => RadioListTile<String>(
                title: Text(estado, style: const TextStyle(fontSize: 14)),
                value: estado,
                groupValue: _estado,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (value) => setState(() => _estado = value!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Periodo de pago',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _periodo,
                isExpanded: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items:
                    periodos
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) async {
                  setState(() => _periodo = value!);
                  if (value == 'Personalizado') {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dateRange = picked);
                  } else {
                    _dateRange = null;
                  }
                },
              ),
            ),
            if (_periodo == 'Personalizado' && _dateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Del ${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} '
                  'al ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics_outlined, size: 20),
          label: const Text('Ver informe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          onPressed:
              _periodo == 'Personalizado' && _dateRange == null
                  ? null
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
