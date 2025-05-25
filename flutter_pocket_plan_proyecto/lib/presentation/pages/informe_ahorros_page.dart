import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/repositories/simulador_ahorro_repository.dart';
import '../../data/models/simulador_ahorro.dart';
import '../providers/user_provider.dart';
import '../widgets/dialogo_filtro_informe_ahorros.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../widgets/global_components.dart';

String _formatearFecha(DateTime fecha) {
  return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
}

class InformeAhorrosPage extends StatefulWidget {
  final String estado; // 'Todos', 'Completados', 'Aún no completados'
  final String
  periodo; // 'Ahorros Mensuales', 'Ahorros Quincenales', 'Personalizado'
  final DateTimeRange? dateRange;

  const InformeAhorrosPage({
    Key? key,
    required this.estado,
    required this.periodo,
    this.dateRange,
  }) : super(key: key);

  @override
  State<InformeAhorrosPage> createState() => _InformeAhorrosPageState();
}

class _InformeAhorrosPageState extends State<InformeAhorrosPage> {
  List<SimuladorAhorro> _simuladores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSimuladores();
  }

  Future<void> _loadSimuladores() async {
    setState(() => _loading = true);

    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userId = userProvider.usuario?.id ?? 0;
    final repo = SimuladorAhorroRepository();

    List<SimuladorAhorro> lista = await repo.getSimuladoresAhorroByUser(userId);

    // FILTRO POR ESTADO
    if (widget.estado == 'Completados') {
      lista = lista.where((s) => s.progreso >= 1.0).toList();
    } else if (widget.estado == 'Aún no completados') {
      lista = lista.where((s) => s.progreso < 1.0).toList();
    }

    // FILTRO POR PERIODO
    if (widget.periodo == 'Ahorros Mensuales') {
      lista = lista.where((s) => s.periodo.toLowerCase() == 'mensual').toList();
    } else if (widget.periodo == 'Ahorros Quincenales') {
      lista =
          lista.where((s) => s.periodo.toLowerCase() == 'quincenal').toList();
    }

    // FILTRO POR FECHA
    if (widget.dateRange != null) {
      lista =
          lista.where((s) {
            return s.fechaInicio.isAfter(
                  widget.dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                s.fechaInicio.isBefore(
                  widget.dateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
    }

    setState(() {
      _simuladores = lista;
      _loading = false;
    });
  }

  void _abrirDialogoFiltro() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => DialogoFiltroInformeAhorros(
            estadoActual: widget.estado,
            periodoActual: widget.periodo,
            rangoActual: widget.dateRange,
          ),
    );
    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => GlobalLayout(
                titulo: "Informe de Ahorros",
                body: InformeAhorrosPage(
                  estado: result['estado'] ?? widget.estado,
                  periodo: result['periodo'] ?? widget.periodo,
                  dateRange: result['dateRange'],
                ),
                mostrarDrawer: true,
                navIndex: 2, // o el índice que corresponda a este módulo
                mostrarBotonInforme: true,
                tipoInforme: 'ahorro',
              ),
        ),
      );
    }
  }

  Future<void> _generarPDF() async {
    // ==== PALETA DE COLORES MODERNA ====
    final azulPrimario = PdfColor(13 / 255, 71 / 255, 161 / 255); // #0D47A1
    final turquesa = PdfColor(24 / 255, 188 / 255, 156 / 255); // #18BC9C
    final azulClaro = PdfColor(0 / 255, 176 / 255, 255 / 255); // #00B0FF
    final fondoTarjeta = PdfColor(236 / 255, 247 / 255, 242 / 255); // #ECF7F2
    final fondoSuave = PdfColor(
      230 / 255,
      247 / 255,
      255 / 255,
    ); // azul claro para sombras

    // ==== ESTILOS DE TEXTO ====
    final titleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 22,
      color: azulPrimario,
    );
    final subtitleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: turquesa,
    );
    final sectionStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 17,
      color: azulClaro,
    );
    final labelStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
      color: azulPrimario,
    );
    final valueStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.normal,
      fontSize: 12,
      color: turquesa,
    );

    // ==== FECHA Y LOGO ====
    String formatear(DateTime f) =>
        "${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}";
    final fechaGeneracion = formatear(DateTime.now());

    // ---- Diálogo de carga elegante ----
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
                  color: Color(0xFF0D47A1),
                  strokeWidth: 4,
                ),
                SizedBox(height: 24),
                Text(
                  'Generando PDF del informe de ahorros...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
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

    // ==== LOGO ====
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/img/pocketplan.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build:
            (context) => [
              // ===== ENCABEZADO =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PocketPlan', style: titleStyle),
                      pw.SizedBox(height: 2),
                      pw.Text('Informe de Ahorros', style: subtitleStyle),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Fecha de generación: $fechaGeneracion',
                        style: pw.TextStyle(fontSize: 11, color: azulPrimario),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: fondoTarjeta,
                          borderRadius: pw.BorderRadius.circular(7),
                        ),
                        child: pw.Text(
                          "Filtros: ${widget.estado} | ${widget.periodo}"
                          "${widget.dateRange != null ? " | ${formatear(widget.dateRange!.start)} - ${formatear(widget.dateRange!.end)}" : ""}",
                          style: pw.TextStyle(fontSize: 11, color: azulClaro),
                        ),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(12),
                        color: fondoSuave,
                        border: pw.Border.all(color: azulClaro, width: 2),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 12,
                        verticalRadius: 12,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                ],
              ),
              pw.Divider(thickness: 1.2, color: azulClaro),
              pw.SizedBox(height: 16),

              // ===== LISTA DE SIMULADORES =====
              if (_simuladores.isEmpty)
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "No hay planes de ahorro para los filtros seleccionados.",
                    style: pw.TextStyle(
                      color: PdfColor(0.6, 0.6, 0.6),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._simuladores.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final sim = entry.value;
                  final porcentaje = (sim.progreso * 100).clamp(0, 100);

                  final barraFondo = PdfColor(
                    220 / 255,
                    245 / 255,
                    255 / 255,
                  ); // azul claro
                  final barraProgreso = azulClaro;

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 26),
                    decoration: pw.BoxDecoration(
                      color: fondoTarjeta,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: azulClaro, width: 1),
                      boxShadow: [
                        pw.BoxShadow(blurRadius: 4, color: fondoSuave),
                      ],
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // === Título y barra de progreso ===
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              decoration: pw.BoxDecoration(
                                color: azulClaro,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              width: 34,
                              height: 34,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                "°-°", // Carita
                                style: pw.TextStyle(
                                  fontSize: 19,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFFFFFFFF),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Text(
                                "Plan de Ahorro #$i",
                                style: sectionStyle,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color:
                                    porcentaje >= 100
                                        ? PdfColor(
                                          222 / 255,
                                          255 / 255,
                                          242 / 255,
                                        )
                                        : PdfColor(
                                          232 / 255,
                                          248 / 255,
                                          255 / 255,
                                        ),
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                porcentaje >= 100
                                    ? "¡Completado!"
                                    : "${porcentaje.toStringAsFixed(1)}%",
                                style: pw.TextStyle(
                                  color:
                                      porcentaje >= 100 ? turquesa : azulClaro,
                                  fontWeight: pw.FontWeight.bold,
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
                            color: barraFondo,
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                          child: pw.Stack(
                            children: [
                              pw.Container(
                                width: (porcentaje / 100) * 420,
                                height: 12,
                                decoration: pw.BoxDecoration(
                                  color: barraProgreso,
                                  borderRadius: pw.BorderRadius.circular(7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 18),
                        // === Detalles del plan ===
                        pw.Text(
                          "Detalles del plan de ahorro",
                          style: subtitleStyle.copyWith(fontSize: 14),
                        ),
                        pw.SizedBox(height: 7),
                        _datoPDF(
                          "Objetivo del Ahorro",
                          sim.objetivo,
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Periodo del Ahorro",
                          sim.periodo,
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Monto total a ahorrar",
                          "Q${sim.monto.toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Monto inicial",
                          "Q${sim.montoInicial.toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Monto ahorrado hasta ahora",
                          "Q${(sim.montoInicial + sim.progreso * (sim.monto - sim.montoInicial)).toStringAsFixed(2)}",
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Fecha de inicio",
                          formatear(sim.fechaInicio),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Fecha de fin",
                          formatear(sim.fechaFin),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Pagos totales previstos",
                          sim.totalPagos.toString(),
                          labelStyle,
                          valueStyle,
                        ),
                        _datoPDF(
                          "Cuota sugerida por periodo",
                          "Q${sim.cuotaSugerida.toStringAsFixed(2)}",
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
      onLayout: (format) async => pdf.save(),
      name: 'informe_ahorros_pocketplan.pdf',
    );
  }

  // Helper para filas label-valor en PDF
  pw.Widget _datoPDF(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 170, child: pw.Text(label, style: labelStyle)),
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
        automaticallyImplyLeading:
            false, // <- esto oculta la flecha de regresar
        leading: null, // <- explícitamente nulo
        title: null, // <- sin título
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Color(0xFF18BC9C)),
            tooltip: 'Cambiar filtros',
            onPressed: _abrirDialogoFiltro,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF18BC9C)),
            tooltip: 'Exportar PDF',
            onPressed: _simuladores.isEmpty ? null : _generarPDF,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Text(
                      'Informe de Ahorros',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF18BC9C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _simuladores.isEmpty
                            ? const Center(
                              child: Text(
                                'No hay planes de ahorro para los filtros seleccionados.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              itemCount: _simuladores.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 20),
                              itemBuilder: (context, i) {
                                final sim = _simuladores[i];
                                return SimuladorAhorroCard(simulador: sim);
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

// CARD DE SIMULADOR DE AHORRO
class SimuladorAhorroCard extends StatelessWidget {
  final SimuladorAhorro simulador;
  const SimuladorAhorroCard({Key? key, required this.simulador})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double porcentaje = (simulador.progreso * 100).clamp(0, 100);

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y barra de progreso
            Row(
              children: [
                const Icon(Icons.savings, color: Color(0xFF18BC9C), size: 35),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Detalles del plan de ahorro",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        porcentaje >= 100
                            ? Colors.green[50]
                            : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    porcentaje >= 100
                        ? "¡Completado!"
                        : "${porcentaje.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: porcentaje >= 100 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: porcentaje / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF18BC9C),
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 20),

            _dato("Objetivo del Ahorro", simulador.objetivo),
            _dato("Periodo del Ahorro", simulador.periodo),
            _dato(
              "Monto total a ahorrar",
              "Q${simulador.monto.toStringAsFixed(2)}",
            ),
            _dato(
              "Monto inicial",
              "Q${simulador.montoInicial.toStringAsFixed(2)}",
            ),
            _dato(
              "Monto ahorrado hasta ahora",
              "Q${(simulador.montoInicial + simulador.progreso * (simulador.monto - simulador.montoInicial)).toStringAsFixed(2)}",
            ),
            _dato("Fecha de inicio", _formatearFecha(simulador.fechaInicio)),
            _dato("Fecha de fin", _formatearFecha(simulador.fechaFin)),
            _dato("Pagos totales previstos", simulador.totalPagos.toString()),
            _dato(
              "Cuota sugerida por periodo",
              "Q${simulador.cuotaSugerida.toStringAsFixed(2)}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF18BC9C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
