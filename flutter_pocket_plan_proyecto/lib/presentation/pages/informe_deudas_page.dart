import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/simulador_deuda_repository.dart';
import '../../data/models/simulador_deuda.dart';
import '../providers/user_provider.dart';
import '../widgets/dialogo_filtro_informe_deudas.dart';
import '../widgets/global_components.dart';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class InformeDeudasPage extends StatefulWidget {
  final String estado;
  final String periodo;
  final DateTimeRange? dateRange;

  const InformeDeudasPage({
    Key? key,
    required this.estado,
    required this.periodo,
    this.dateRange,
  }) : super(key: key);

  @override
  State<InformeDeudasPage> createState() => _InformeDeudasPageState();
}

class _InformeDeudasPageState extends State<InformeDeudasPage> {
  List<SimuladorDeuda> _deudas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeudas();
  }

  Future<void> _loadDeudas() async {
    setState(() => _loading = true);

    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userId = userProvider.usuario?.id ?? 0;
    final repo = SimuladorDeudaRepository();

    List<SimuladorDeuda> lista = await repo.getSimuladoresDeudaByUser(userId);

    if (widget.estado == 'Completados') {
      lista = lista.where((d) => d.progreso >= 1.0).toList();
    } else if (widget.estado == 'Pendientes') {
      lista = lista.where((d) => d.progreso < 1.0).toList();
    }

    if (widget.periodo == 'Mensual') {
      lista = lista.where((d) => d.periodo.toLowerCase() == 'mensual').toList();
    } else if (widget.periodo == 'Quincenal') {
      lista =
          lista.where((d) => d.periodo.toLowerCase() == 'quincenal').toList();
    }

    if (widget.dateRange != null) {
      lista =
          lista.where((d) {
            return d.fechaInicio.isAfter(
                  widget.dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                d.fechaInicio.isBefore(
                  widget.dateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
    }

    setState(() {
      _deudas = lista;
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _abrirDialogoFiltro() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DialogoFiltroInformeDeudas(),
    );

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => GlobalLayout(
                titulo: "Informe de Deudas",
                body: InformeDeudasPage(
                  estado: result['estado'] ?? 'Todas',
                  periodo: result['periodo'] ?? 'Todos los periodos',
                  dateRange: result['dateRange'],
                ),
                mostrarDrawer: true,
                navIndex: 2,
                mostrarBotonInforme: true,
                tipoInforme: 'deuda',
              ),
        ),
      );
    }
  }

  Future<void> _generarPDF() async {
    // Paleta moderna
    final verdeOscuro = PdfColor.fromHex("#2E7D32");
    final verdeIntermedio = PdfColor.fromHex("#388E3C");
    final verdeClaro = PdfColor.fromHex("#66BB6A");
    final grisFondo = PdfColor.fromHex("#F4F8F6");
    final grisLinea = PdfColor.fromHex("#CFD8DC");
    final grisTexto = PdfColor.fromHex("#37474F");

    // Estilos
    final titleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 22,
      color: verdeOscuro,
    );
    final subtitleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: verdeIntermedio,
    );
    final labelStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 14.5,
      color: verdeOscuro,
    );
    final valueStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.normal,
      fontSize: 14.5,
      color: verdeIntermedio,
    );
    final avanceStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 13.5,
      color: verdeOscuro,
    );

    // Formateador de fecha
    String formatear(DateTime f) =>
        "${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}";
    final fechaGeneracion = formatear(DateTime.now());

    // Mostrar diálogo de carga elegante
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                  strokeWidth: 4,
                ),
                SizedBox(height: 24),
                Text(
                  'Generando PDF del informe de deudas...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 19,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simula un pequeño delay para realismo
    await Future.delayed(const Duration(milliseconds: 1200));

    // LOGO
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/img/pocketplan.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // Crear documento PDF
    final pdf = pw.Document();

    // Añade una página moderna
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build:
            (context) => [
              // ===== ENCABEZADO MODERNO: Logo a la derecha, texto a la izquierda =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Texto alineado a la izquierda
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PocketPlan', style: titleStyle),
                      pw.SizedBox(height: 2),
                      pw.Text('Informe de Deudas', style: subtitleStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Fecha de generación: $fechaGeneracion',
                        style: pw.TextStyle(
                          fontSize: 12.5,
                          color: titleStyle.color,
                        ),
                      ),
                    ],
                  ),
                  // Logo grande a la derecha
                  if (logoImage != null)
                    pw.Container(
                      width: 75,
                      height: 75,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(18),
                        color: grisFondo,
                        border: pw.Border.all(color: verdeClaro, width: 2),
                        boxShadow: [
                          pw.BoxShadow(
                            blurRadius: 5,
                            color: PdfColor.fromHex("#DDDDDD"),
                          ),
                        ],
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(7.5),
                        child: pw.ClipRRect(
                          horizontalRadius: 18,
                          verticalRadius: 18,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 6),
              // Bloque de filtros
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: grisFondo,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  "Filtros: ${widget.estado} | ${widget.periodo}"
                  "${widget.dateRange != null ? " | ${formatear(widget.dateRange!.start)} - ${formatear(widget.dateRange!.end)}" : ""}",
                  style: pw.TextStyle(fontSize: 13.5, color: verdeIntermedio),
                ),
              ),
              pw.Divider(thickness: 1.2, color: grisLinea),
              pw.SizedBox(height: 16),

              // ===== LISTA DE DEUDAS =====
              if (_deudas.isEmpty)
                pw.Center(
                  child: pw.Text(
                    'No hay deudas para los filtros seleccionados.',
                    style: pw.TextStyle(color: grisTexto, fontSize: 15),
                  ),
                )
              else
                ..._deudas.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final deuda = entry.value;
                  final porcentaje = (deuda.progreso * 100).clamp(0, 100);

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 22),
                    decoration: pw.BoxDecoration(
                      color: grisFondo,
                      borderRadius: pw.BorderRadius.circular(13),
                      border: pw.Border.all(color: verdeClaro, width: 1),
                      boxShadow: [
                        pw.BoxShadow(blurRadius: 2, color: grisLinea),
                      ],
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Título y barra de progreso
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: verdeClaro,
                                borderRadius: pw.BorderRadius.circular(9),
                              ),
                              width: 38,
                              height: 38,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                "°-°",
                                style: pw.TextStyle(
                                  fontSize: 22, // Más grande la carita
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFFFFFFFF),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Text(
                                "Detalle de la Deuda #$i",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: verdeIntermedio,
                                  fontSize: 15.2,
                                ),
                              ),
                            ),

                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color:
                                    verdeIntermedio, // Fondo siempre verde fuerte
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                porcentaje >= 100
                                    ? "¡Completado!"
                                    : "${porcentaje.toStringAsFixed(1)}%",
                                style: pw.TextStyle(
                                  color: PdfColor.fromInt(
                                    0xFFFFFFFF,
                                  ), // Siempre texto blanco
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        // Barra de progreso
                        pw.Container(
                          width: double.infinity,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            color: grisLinea,
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                          child: pw.Stack(
                            children: [
                              pw.Container(
                                width: (porcentaje / 100) * 420,
                                height: 12,
                                decoration: pw.BoxDecoration(
                                  color: verdeClaro,
                                  borderRadius: pw.BorderRadius.circular(7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        // === Detalles de la deuda
                        _datoPDF(
                          "Motivo de la Deuda",
                          deuda.motivo,
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Periodo de Pago",
                          deuda.periodo,
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Monto Total",
                          "Q${deuda.monto.toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Monto Cancelado",
                          "Q${deuda.montoCancelado.toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Fecha de Inicio",
                          formatear(deuda.fechaInicio),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Fecha de Fin",
                          formatear(deuda.fechaFin),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Pagos pendientes",
                          deuda.totalPagos.toString(),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Pago sugerido",
                          "Q${deuda.pagoSugerido.toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                      ],
                    ),
                  );
                }),
            ],
      ),
    );

    // Cerrar el diálogo de carga
    if (context.mounted) Navigator.pop(context);

    // Mostrar vista previa del PDF y permitir compartir/guardar
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'informe_deudas_pocketplan.pdf',
    );
  }

  // === Helper elegante para filas label-valor en PDF ===
  pw.Widget _datoPDF(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 150, child: pw.Text(label, style: labelStyle)),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Color(0xFF2E7D32)),
            tooltip: 'Cambiar filtros',
            onPressed:
                _abrirDialogoFiltro, // Asegúrate de tener esta función implementada
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF2E7D32)),
            tooltip: 'Exportar PDF',
            onPressed:
                _deudas.isEmpty
                    ? null
                    : _generarPDF, // Asegúrate de tener esta función implementada
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _deudas.isEmpty
              ? const Center(
                child: Text('No hay deudas para los filtros seleccionados.'),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _deudas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final deuda = _deudas[i];
                  final porcentaje = (deuda.progreso * 100).clamp(0, 100);

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.money_off, color: Color(0xFF2E7D32)),
                              SizedBox(width: 10),
                              Text(
                                'Detalle de la Deuda',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _dato('Motivo de la Deuda', deuda.motivo),
                          _dato('Periodo de Pago', deuda.periodo),
                          _dato(
                            'Monto Total',
                            'Q${deuda.monto.toStringAsFixed(2)}',
                          ),
                          _dato(
                            'Monto Cancelado',
                            'Q${deuda.montoCancelado.toStringAsFixed(2)}',
                          ),
                          _dato(
                            'Fecha de Inicio',
                            _formatDate(deuda.fechaInicio),
                          ),
                          _dato('Fecha de Fin', _formatDate(deuda.fechaFin)),
                          _dato('Pagos Pendientes', '${deuda.totalPagos}'),
                          _dato(
                            'Pago Sugerido',
                            'Q${deuda.pagoSugerido.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: deuda.progreso,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Avance: ${porcentaje.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _dato(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF4E5D6A)),
            ),
          ),
        ],
      ),
    );
  }
}
