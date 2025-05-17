class Movimiento {
  final String tipo;           // 'ingreso' o 'egreso'
  final DateTime fecha;
  final double monto;
  final String concepto;
  final String etiqueta;
  final String? metodoPago;    // solo para egresos
  final String? tarjetaId;     // solo para egresos con tarjeta
  final String? tipoTarjeta;   // 'Débito' o 'Crédito', solo egresos con tarjeta
  final String? opcionPago;    // 'Al contado' o 'A cuotas', solo crédito
  final int? cuotas;           // solo si opcionPago == 'A cuotas'

  Movimiento({
    required this.tipo,
    required this.fecha,
    required this.monto,
    required this.concepto,
    required this.etiqueta,
    this.metodoPago,
    this.tarjetaId,
    this.tipoTarjeta,
    this.opcionPago,
    this.cuotas,
  });

  // Para debug/log
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'concepto': concepto,
      'etiqueta': etiqueta,
      'metodoPago': metodoPago,
      'tarjetaId': tarjetaId,
      'tipoTarjeta': tipoTarjeta,
      'opcionPago': opcionPago,
      'cuotas': cuotas,
    };
  }

  // Si quieres poder crear desde un Map (ejemplo para persistencia local):
  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      tipo: map['tipo'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      monto: (map['monto'] as num).toDouble(),
      concepto: map['concepto'] as String,
      etiqueta: map['etiqueta'] as String,
      metodoPago: map['metodoPago'] as String?,
      tarjetaId: map['tarjetaId'] as String?,
      tipoTarjeta: map['tipoTarjeta'] as String?,
      opcionPago: map['opcionPago'] as String?,
      cuotas: map['cuotas'] as int?,
    );
  }
}
