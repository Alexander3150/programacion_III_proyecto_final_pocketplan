// En /data/models/movimiento_model.dart
class Movimiento {
  final String id;
  final String tipo; // 'ingreso' o 'egreso'
  final DateTime fecha;
  final double monto;
  final String concepto;
  final String etiqueta;
  final String? metodoPago; // Solo para egresos
  final String? tarjetaId; // ID de la tarjeta usada
  final String? tipoTarjeta; // 'Débito' o 'Crédito'
  final String? opcionPago; // 'Al contado' o 'A cuotas'
  final int? cuotas; // Número de cuotas

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
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Conversión a/desde Firebase/Maps
  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'],
      tipo: map['tipo'],
      fecha: DateTime.parse(map['fecha']),
      monto: map['monto'].toDouble(),
      concepto: map['concepto'],
      etiqueta: map['etiqueta'],
      metodoPago: map['metodoPago'],
      tarjetaId: map['tarjetaId'],
      tipoTarjeta: map['tipoTarjeta'],
      opcionPago: map['opcionPago'],
      cuotas: map['cuotas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'concepto': concepto,
      'etiqueta': etiqueta,
      if (metodoPago != null) 'metodoPago': metodoPago,
      if (tarjetaId != null) 'tarjetaId': tarjetaId,
      if (tipoTarjeta != null) 'tipoTarjeta': tipoTarjeta,
      if (opcionPago != null) 'opcionPago': opcionPago,
      if (cuotas != null) 'cuotas': cuotas,
    };
  }

  // Validación básica
  bool isValid() {
    return monto > 0 && concepto.isNotEmpty && etiqueta.isNotEmpty;
  }
}