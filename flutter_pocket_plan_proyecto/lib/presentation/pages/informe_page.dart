import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/models/credit_card_model.dart';
import '../../data/models/debit_card_model.dart';
import '../../data/models/repositories/movimiento_repository.dart';
import '../../data/models/repositories/tarjeta_credito_repository.dart';
import '../../data/models/repositories/tarjeta_debito_repository.dart';
import '../providers/user_provider.dart';
import '../widgets/dialogo_filtro_informe.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../widgets/global_components.dart';

const Map<String, IconData> iconosEtiquetas = {
  'Salario': Icons.monetization_on,
  'Freelance': Icons.work_outline,
  'Inversiones': Icons.trending_up,
  'Regalo': Icons.card_giftcard,
  'Otros': Icons.category,
  'Comida': Icons.restaurant,
  'Transporte': Icons.directions_car,
  'Renta': Icons.home_work_outlined,
  'Entretenimiento': Icons.movie,
  'Servicios': Icons.miscellaneous_services,
};

String formatearFecha(DateTime fecha) {
  return "${fecha.day.toString().padLeft(2, '0')}/"
      "${fecha.month.toString().padLeft(2, '0')}/"
      "${fecha.year}";
}

String _mapTipoToDb(String tipo) {
  switch (tipo) {
    case 'Ingresos':
      return 'ingreso';
    case 'Egresos':
      return 'egreso';
    default:
      return tipo.toLowerCase();
  }
}

class InformePage extends StatefulWidget {
  final String tipo; // 'Todo', 'Ingresos', 'Egresos'
  final String periodo; // 'Día', 'Semana', etc.
  final DateTimeRange? dateRange;

  const InformePage({
    Key? key,
    required this.tipo,
    required this.periodo,
    this.dateRange,
  }) : super(key: key);

  @override
  State<InformePage> createState() => _InformePageState();
}

class _InformePageState extends State<InformePage> {
  List<Movimiento> _movimientos = [];
  bool _loading = true;
  double? presupuestoActual;
  Map<int, CreditCard> _tarjetasCredito = {};
  Map<int, DebitCard> _tarjetasDebito = {};

  @override
  void initState() {
    super.initState();
    _loadInforme();
  }

  Future<void> _loadInforme() async {
    setState(() {
      _loading = true;
    });

    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final userId = userProvider.usuario?.id ?? 0;
    presupuestoActual = userProvider.usuario?.presupuesto;

    final repo = MovimientoRepository();
    List<Movimiento> movimientos;

    if (widget.tipo == 'Todo') {
      movimientos = await repo.getMovimientosByUser(userId);
    } else {
      movimientos = await repo.getMovimientosByTipo(
        userId,
        _mapTipoToDb(widget.tipo),
      );
    }

    if (widget.dateRange != null) {
      movimientos =
          movimientos.where((m) {
            final fecha = m.fecha;
            return fecha.isAfter(
                  widget.dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                fecha.isBefore(
                  widget.dateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
    }

    final tarjetasCreditoRepo = TarjetaCreditoRepository();
    final tarjetasDebitoRepo = TarjetaDebitoRepository();

    final tarjetasCredito = await tarjetasCreditoRepo.getTarjetasCreditoByUser(
      userId,
    );
    final tarjetasDebito = await tarjetasDebitoRepo.getTarjetasDebitoByUser(
      userId,
    );

    final tarjetasCreditoMap = {for (var t in tarjetasCredito) t.id!: t};
    final tarjetasDebitoMap = {for (var t in tarjetasDebito) t.id!: t};

    setState(() {
      _movimientos = movimientos;
      _tarjetasCredito = tarjetasCreditoMap;
      _tarjetasDebito = tarjetasDebitoMap;
      _loading = false;
    });
  }

  void _abrirDialogoFiltro() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => DialogoFiltroInforme(
            tipoActual: widget.tipo,
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
                titulo: "Informe Financiero",
                body: InformePage(
                  tipo: result['tipo'] ?? widget.tipo,
                  periodo: result['periodo'] ?? widget.periodo,
                  dateRange: result['dateRange'],
                ),
                mostrarDrawer: true,
                navIndex: 2,
                mostrarBotonInforme: true,
                tipoInforme: 'financiero',
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presupuesto = presupuestoActual ?? 0.0;
    return Column(
      children: [
        // --- Barra de acciones tipo AppBar personalizada, pero SIN duplicar el AppBar global
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                tooltip: 'Cambiar filtros',
                onPressed: _abrirDialogoFiltro,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar PDF',
                onPressed: _movimientos.isEmpty ? null : _exportarPDF,
              ),
            ],
          ),
        ),
        // --- Mostrando el presupuesto mensual actual
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Card(
            color: const Color(0xFFECF7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: Colors.teal[600],
                size: 36,
              ),
              title: const Text(
                'Presupuesto mensual inicial',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Q${presupuesto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _movimientos.isEmpty
                  ? const Center(
                    child: Text('No hay movimientos en este periodo'),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _movimientos.length,
                    separatorBuilder:
                        (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = _movimientos[i];
                      return MovimientoCard(
                        movimiento: m,
                        tarjetaCredito:
                            m.tipoTarjeta == 'Crédito' && m.tarjetaId != null
                                ? _tarjetasCredito[m.tarjetaId]
                                : null,
                        tarjetaDebito:
                            m.tipoTarjeta == 'Débito' && m.tarjetaId != null
                                ? _tarjetasDebito[m.tarjetaId]
                                : null,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Future<void> _exportarPDF() async {
    // Mostrar diálogo de carga elegante y moderno
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
                  color: Color(0xFF00B0FF),
                  strokeWidth: 4,
                ),
                SizedBox(height: 24),
                Text(
                  'Generando PDF del informe financiero...',
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

    // Simula un pequeño delay para realismo de UX
    await Future.delayed(const Duration(milliseconds: 1200));

    final pdf = pw.Document();

    // Leer logo de assets
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/img/pocketplan.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Colores y estilos
    final baseColor = PdfColor.fromInt(0xFF00B0FF);
    final headerColor = PdfColor.fromInt(0xFFECF7F2);

    final titleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 22,
      color: baseColor,
    );
    final subtitleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 16,
      color: PdfColor.fromInt(0xFF2C3E50),
    );
    final boldStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 13,
      color: PdfColor.fromInt(0xFF2C3E50),
    );

    // Función para formato de fecha
    String formatear(DateTime f) =>
        "${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}";
    final fechaGeneracion = formatear(DateTime.now());

    // Filtra ingresos y egresos
    final ingresos =
        _movimientos.where((m) => m.tipo.toLowerCase() == 'ingreso').toList();
    final egresos =
        _movimientos.where((m) => m.tipo.toLowerCase() == 'egreso').toList();

    double sumaIngresos = ingresos.fold(0.0, (sum, m) => sum + (m.monto ?? 0));
    double sumaEgresos = egresos.fold(0.0, (sum, m) => sum + (m.monto ?? 0));
    double balance = sumaIngresos - sumaEgresos;

    // Construye el PDF
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        build:
            (context) => [
              // Encabezado con logo a la derecha
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ======== BLOQUE DE INFORMACIÓN ========
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Título grande
                        pw.Text(
                          'PocketPlan',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 26,
                            color: baseColor, // Usa tu color principal
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        // Subtítulo
                        pw.Text(
                          'Informe Financiero',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColor.fromInt(0xFF2C3E50),
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        // Fecha
                        pw.Text(
                          'Fecha de generación: $fechaGeneracion',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromInt(0xFF7B8D93),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        // Filtros
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            color: headerColor,
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          margin: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.Text(
                            "Filtros: "
                                    "${widget.tipo} | "
                                    "${widget.periodo}" +
                                (widget.dateRange != null
                                    ? " | ${formatear(widget.dateRange!.start)} - ${formatear(widget.dateRange!.end)}"
                                    : ""),
                            style: pw.TextStyle(fontSize: 13, color: baseColor),
                          ),
                        ),
                        // Presupuesto mensual
                        pw.Text(
                          'Presupuesto mensual actual: Q${(presupuestoActual ?? 0).toStringAsFixed(2)}',
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                  // ======== LOGO A LA DERECHA ========
                  if (logoImage != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      alignment: pw.Alignment.topRight,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // INGRESOS
              pw.Text(
                'INGRESOS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 17,
                  color: PdfColor.fromInt(0xFF298D46),
                ),
              ),
              pw.SizedBox(height: 8),
              ingresos.isEmpty
                  ? pw.Text(
                    'No hay ingresos en este periodo.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromInt(0xFF607D8B),
                    ),
                  )
                  : pw.Table.fromTextArray(
                    headers: ['Fecha', 'Concepto', 'Etiqueta', 'Monto'],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2C3E50),
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFB7E2FA),
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    data:
                        ingresos.map((m) {
                          return [
                            formatear(m.fecha),
                            m.concepto,
                            m.etiqueta,
                            'Q${m.monto.toStringAsFixed(2)}',
                          ];
                        }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 11),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.TableBorder(
                        bottom: pw.BorderSide(
                          color: PdfColor.fromInt(0xFFECECEC),
                          width: .5,
                        ),
                      ),
                    ),
                  ),
              if (ingresos.isNotEmpty)
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 6, bottom: 18),
                  child: pw.Text(
                    'Suma de Ingresos: Q${sumaIngresos.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: PdfColor.fromInt(0xFF298D46),
                    ),
                  ),
                ),

              // EGRESOS
              pw.SizedBox(height: 18),
              pw.Text(
                'EGRESOS',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 17,
                  color: PdfColor.fromInt(0xFFE74C3C),
                ),
              ),
              pw.SizedBox(height: 8),
              egresos.isEmpty
                  ? pw.Text(
                    'No hay egresos en este periodo.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromInt(0xFF607D8B),
                    ),
                  )
                  : pw.Table.fromTextArray(
                    headers: [
                      'Fecha',
                      'Concepto',
                      'Etiqueta',
                      'Monto',
                      'Método',
                      'Detalles Tarjeta',
                    ],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF2C3E50),
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFB7E2FA),
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    data:
                        egresos.map((m) {
                          // Detalles de tarjeta (si aplica)
                          String tarjetaInfo = '';
                          if (m.tarjetaId != null) {
                            if (m.tipoTarjeta == 'Crédito' &&
                                _tarjetasCredito[m.tarjetaId] != null) {
                              final t = _tarjetasCredito[m.tarjetaId]!;
                              tarjetaInfo =
                                  'Crédito: ${t.banco}\n${t.alias}\n${t.numero}${m.opcionPago != null ? '\nPago: ${m.opcionPago}' : ''}${(m.opcionPago == 'A cuotas' && m.cuotas != null) ? '\nCuotas: ${m.cuotas}' : ''}';
                            } else if (m.tipoTarjeta == 'Débito' &&
                                _tarjetasDebito[m.tarjetaId] != null) {
                              final t = _tarjetasDebito[m.tarjetaId]!;
                              tarjetaInfo =
                                  'Débito: ${t.banco}\n${t.alias}\n${t.numero}';
                            }
                          }

                          return [
                            formatear(m.fecha),
                            m.concepto,
                            m.etiqueta,
                            'Q${m.monto.toStringAsFixed(2)}',
                            m.metodoPago ?? '',
                            tarjetaInfo,
                          ];
                        }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 11),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.TableBorder(
                        bottom: pw.BorderSide(
                          color: PdfColor.fromInt(0xFFECECEC),
                          width: .5,
                        ),
                      ),
                    ),
                  ),
              if (egresos.isNotEmpty)
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 6, bottom: 18),
                  child: pw.Text(
                    'Suma de Egresos: Q${sumaEgresos.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      color: PdfColor.fromInt(0xFFE74C3C),
                    ),
                  ),
                ),

              // BALANCE
              pw.Divider(height: 32),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'BALANCE FINAL: Q${balance.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 15,
                    color:
                        balance >= 0
                            ? PdfColor.fromInt(0xFF18BC9C)
                            : PdfColor.fromInt(0xFFE74C3C),
                  ),
                ),
              ),
            ],
      ),
    );

    // Cierra el diálogo de carga
    if (context.mounted) Navigator.pop(context);

    // Abre vista previa para imprimir o compartir
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'informe_financiero_pocketplan.pdf',
    );
  }
}

// Card individual de movimiento, con detalles completos y de tarjeta si aplica
class MovimientoCard extends StatelessWidget {
  final Movimiento movimiento;
  final CreditCard? tarjetaCredito;
  final DebitCard? tarjetaDebito;

  const MovimientoCard({
    Key? key,
    required this.movimiento,
    this.tarjetaCredito,
    this.tarjetaDebito,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo.toLowerCase() == 'ingreso';
    final montoStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: esIngreso ? Colors.green[700] : Colors.red[700],
      fontSize: 16,
    );
    Widget? detallesTarjeta;
    if (!esIngreso &&
        movimiento.metodoPago != null &&
        movimiento.tarjetaId != null) {
      if (movimiento.tipoTarjeta == 'Crédito' && tarjetaCredito != null) {
        detallesTarjeta = Padding(
          padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Banco: ${tarjetaCredito!.banco}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Text(
                'Propietario: ${tarjetaCredito!.alias}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Text(
                'Número: ${tarjetaCredito!.numero}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Text(
                'Opción de pago: ${movimiento.opcionPago ?? ""}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (movimiento.opcionPago == 'A cuotas' &&
                  movimiento.cuotas != null)
                Text(
                  'Nº de cuotas: ${movimiento.cuotas}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
        );
      } else if (movimiento.tipoTarjeta == 'Débito' && tarjetaDebito != null) {
        detallesTarjeta = Padding(
          padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Banco: ${tarjetaDebito!.banco}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Text(
                'Propietario: ${tarjetaDebito!.alias}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Text(
                'Número: ${tarjetaDebito!.numero}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        );
      }
    }

    final iconoEtiqueta = iconosEtiquetas[movimiento.etiqueta] ?? Icons.label;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concepto y monto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    movimiento.concepto,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Q${movimiento.monto.toStringAsFixed(2)}',
                  style: montoStyle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Fecha y tipo
            Row(
              children: [
                Icon(
                  esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                  color: esIngreso ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  esIngreso ? 'Ingreso' : 'Egreso',
                  style: TextStyle(
                    color: esIngreso ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 15,
                  color: Color(0xFF90A4AE),
                ),
                const SizedBox(width: 4),
                Text(
                  formatearFecha(movimiento.fecha),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Etiqueta personalizada
            Row(
              children: [
                Icon(iconoEtiqueta, size: 18),
                const SizedBox(width: 6),
                Text(
                  movimiento.etiqueta,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (!esIngreso) ...[
              const SizedBox(height: 7),
              Text(
                'Método de pago: ${movimiento.metodoPago ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
              if (detallesTarjeta != null) detallesTarjeta,
            ],
          ],
        ),
      ),
    );
  }
}
